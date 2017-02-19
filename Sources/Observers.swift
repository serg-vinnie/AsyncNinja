//
//  Copyright (c) 2016-2017 Anton Mironov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom
//  the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
  import Foundation

  // MARK: - regular observation
  public extension Retainer where Self: NSObject {
    /// makes channel of changes of value for specified key path
    ///
    /// - Parameter keyPath: to observe
    /// - Parameter observationSession: is an object that helps to control observation
    /// - Parameter channelBufferSize: size of the buffer within returned channel
    /// - Returns: channel new values
    func changes<T>(
      of keyPath: String,
      observationSession: ObservationSession? = nil,
      channelBufferSize: Int = 1
      ) -> Updating<T?> {
      return changesDictionary(of: keyPath, options: [.initial, .new], observationSession: observationSession)
        .map(executor: .immediate) { $0[.newKey] as? T }
    }

    /// makes channel of changes of value for specified key path
    ///
    /// - Parameter keyPath: to observe
    /// - Parameter observationSession: is an object that helps to control observation
    /// - Parameter channelBufferSize: size of the buffer within returned channel
    /// - Returns: channel of pairs (old, new) values
    func changesOldAndNew<T>(
      of keyPath: String,
      observationSession: ObservationSession? = nil,
      channelBufferSize: Int = 1
      ) -> Updating<(old: T?, new: T?)> {
      return changesDictionary(of: keyPath, options: [.initial, .new, .old], observationSession: observationSession)
        .map(executor: .immediate) {
          (old: $0[.oldKey] as? T, new: $0[.newKey] as? T)
      }
    }

    /// makes channel of changes of value for specified key path
    ///
    /// - Parameter keyPath: to observe
    /// - Parameter observationSession: is an object that helps to control observation
    /// - Parameter channelBufferSize: size of the buffer within returned channel
    /// - Returns: channel of changes dictionaries (see Foundation KVO for details)
    func changesDictionary(
      of keyPath: String,
      options: NSKeyValueObservingOptions,
      observationSession: ObservationSession? = nil,
      channelBufferSize: Int = 1
      ) -> Updating<[NSKeyValueChangeKey: Any]> {
      let producer = Updatable<[NSKeyValueChangeKey: Any]>(bufferSize: channelBufferSize)

      let observer = KeyPathObserver(object: self, keyPath: keyPath, options: options, enabled: observationSession?.enabled ?? true) {
        [weak producer] (changes) in
        producer?.update(changes)
      }

      observationSession?.observers.push(observer)
      notifyDeinit { [weak producer] in
        producer?.cancelBecauseOfDeallocatedContext()
        observer.enabled = false
      }

      return producer
    }
  }

  private class KeyPathObserver: NSObject {
    let object: Unmanaged<NSObject>
    let keyPath: String
    let options: NSKeyValueObservingOptions
    let observationBlock: ([NSKeyValueChangeKey: Any]) -> Void
    var enabled: Bool {
      didSet {
        if enabled == oldValue {
          return
        } else if enabled {
          object.takeUnretainedValue().addObserver(self, forKeyPath: keyPath, options: options, context: nil)
        } else {
          object.takeUnretainedValue().removeObserver(self, forKeyPath: keyPath)
        }
      }
    }

    init(object: NSObject, keyPath: String, options: NSKeyValueObservingOptions, enabled: Bool, observationBlock: @escaping ([NSKeyValueChangeKey: Any]) -> Void) {
      self.object = Unmanaged.passUnretained(object)
      self.keyPath = keyPath
      self.options = options
      self.observationBlock = observationBlock
      self.enabled = enabled
      super.init()
      if enabled {
        object.addObserver(self, forKeyPath: keyPath, options: options, context: nil)
      }
    }

    deinit {
      self.enabled = false
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
      assert(keyPath == self.keyPath)
      if let change = change {
        observationBlock(change)
      }
    }
  }

  /// An object that is able to control (enable and disable) observation-related channel constructors
  public class ObservationSession {

    /// enables or disables observation
    public var enabled: Bool {
      didSet {
        if enabled != oldValue {
          observers.forEach {
            $0.enabled = enabled
          }
        }
      }
    }

    fileprivate var observers = QueueOfWeakElements<KeyPathObserver>()

    /// designated initializer
    public init(enabled: Bool = true) {
      self.enabled = enabled
    }
  }
#endif

#if os(macOS)
  import AppKit

  /// NSControl improved with AsyncNinja
  public extension NSControl {
    /// Update of ActionChannel
    typealias ActionChannelUpdate = (sender: AnyObject?, objectValue: Any?)

    /// Channel that contains actions sent by the control
    typealias ActionChannel = Updating<ActionChannelUpdate>

    /// Makes or returns cached channel. The channel that will have update on each triggering of action
    func actionChannel() -> ActionChannel {
      let actionReceiver = (self.target as? ActionReceiver) ?? {
        let actionReceiver = ActionReceiver(control: self)
        self.target = actionReceiver
        self.notifyDeinit {
          actionReceiver.producer.cancelBecauseOfDeallocatedContext()
        }
        return actionReceiver
        }()

      self.action = #selector(ActionReceiver.asyncNinjaAction(sender:))
      return actionReceiver.producer
    }
  }

  private class ActionReceiver: NSObject {
    weak var control: NSControl?
    let producer = Updatable<NSControl.ActionChannelUpdate>(bufferSize: 0)

    init(control: NSControl) {
      self.control = control
    }

    dynamic func asyncNinjaAction(sender: AnyObject?) {
      let update: NSControl.ActionChannelUpdate = (
        sender: sender,
        objectValue: self.control?.objectValue
      )
      self.producer.update(update)
    }
  }
#endif

#if os(iOS) || os(tvOS)
  import UIKit

  /// UIControl improved with AsyncNinja
  public extension UIControl {
    /// Update of ActionChannel
    typealias ActionChannelUpdate = (sender: AnyObject?, event: UIEvent)

    /// Channel that contains actions sent by the control
    typealias ActionChannel = Updating<ActionChannelUpdate>

    /// Makes channel that will have update value on each triggering of action
    ///
    /// - Parameter events: events that to listen for
    /// - Returns: unbuffered channel
    func actionChannel(forEvents events: UIControlEvents = UIControlEvents.allEvents) -> ActionChannel {
      let actionReceiver = ActionReceiver(control: self)
      self.addTarget(actionReceiver,
                     action: #selector(ActionReceiver.asyncNinjaAction(sender:forEvent:)),
                     for: events)
      self.notifyDeinit {
        actionReceiver.producer.cancelBecauseOfDeallocatedContext()
      }

      return actionReceiver.producer
    }
  }

  private class ActionReceiver: NSObject {
    weak var control: UIControl?
    let producer = Updatable<UIControl.ActionChannelUpdate>(bufferSize: 0)

    init(control: UIControl) {
      self.control = control
    }

    dynamic func asyncNinjaAction(sender: AnyObject?, forEvent event: UIEvent) {
      let update: UIControl.ActionChannelUpdate = (
        sender: sender,
        event: event
      )
      self.producer.update(update)
    }
  }
#endif
