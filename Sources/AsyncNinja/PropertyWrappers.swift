//
//  Copyright (c) 2016-2020 Anton Mironov, Sergiy Vynnychenko
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

import Foundation
import Essentials

/// using: @WrappedProducer var variable = "String Value"
/// variable can be used as usual
/// channel can be accessed as $variable
@propertyWrapper public struct WrappedProducer<Value> {
  public var wrappedValue : Value { didSet { _producer.update(wrappedValue, from: .main)  } }
  
  /// The property that can be accessed with the `$` syntax and allows access to the `Channel`
  public var projectedValue: Channel<Value, Void> { get { return _producer } }
  
  private let _producer : Producer<Value, Void>
  
  /// Initialize the storage of the Published property as well as the corresponding `Publisher`.
  public init(wrappedValue: Value) {
    self.wrappedValue = wrappedValue
    self._producer = Producer<Value,Void>(bufferSize: 1, bufferedUpdates: [wrappedValue])
  }
}

public struct Feedback {
  let log: ((String)->())?
  let error: ((Error)->())?
}

public struct ResultBinding<Value> {
  let getter: ()->R<Value>
  let setter: (R<Value>)->R<Void>
  let executor: Executor?
  let feedback: Feedback?
  
  public init(getter: @escaping () -> R<Value>, setter: @escaping (R<Value>) -> R<Void>, executor: Executor? = nil, feedback: Feedback? = nil) {
    self.getter = getter
    self.setter = setter
    self.executor = executor
    self.feedback = feedback
  }
}

@propertyWrapper public struct OptionalProducer<Value> {
  public var wrappedValue : Value? {
    set {
      guard let v = newValue else { return }
      let p = _producer
      guard let binding = _binding else {
        DispatchQueue.main.sync {
          p.update(v)
        }
        return
      }
      
      binding.setter(.success(v))
        .onSuccess { DispatchQueue.main.sync { p.update(v) } }
        .onFailure { error in _binding?.feedback?.error?(error) }
    }
    get {
      _producer._bufferedUpdates.last
    }
  }

  /// The property that can be accessed with the `$` syntax and allows access to the `Channel`
  public var projectedValue: Channel<Value, Void> { get { return _producer } }
  
  private let _producer : Producer<Value, Void>
  private let _refresher : Refresher<Value>
  private let _binding: ResultBinding<Value>?
  
  @discardableResult
  public func refresh() -> Future<Value> { _refresher.refresh() }
  
  /// Initialize the storage of the Published property as well as the corresponding `Publisher`.
  public init(_ binding: ResultBinding<Value>? = nil) {
    let _p : Producer<Value, Void>
    
    if let binding = binding, binding.executor == nil, let value = binding.getter().maybeSuccess {
      _p = Producer<Value,Void>(bufferSize: 1, bufferedUpdates: [value])
    } else {
      _p = Producer<Value,Void>(bufferSize: 1)
    }
    
    _producer = _p
    _refresher = .init(producer: _p, bidning: binding)
    _binding = binding
    
    if let _ = binding?.executor {
      _ = _refresher.refresh()
    }
  }
}

class Refresher<Value> : ExecutionContext, ReleasePoolOwner {
  public var executor    = Executor.init(queue: DispatchQueue.global(qos: .userInteractive))
  public let releasePool = ReleasePool()
  
  private let _producer : Producer<Value, Void>
  private let _binding: ResultBinding<Value>?
  
  init(producer: Producer<Value, Void>, bidning: ResultBinding<Value>?) {
    self._producer = producer
    self._binding = bidning
  }
  
  func refresh() -> Future<Value> {
    guard let binding = _binding else {  return .failed(WTF("_binding == nil")) }
    
    if let executor = binding.executor {
      return self.promise(executor: executor) { me, promise  in
        binding.feedback?.log?("refreshing")
        promise.complete(binding.getter())
      }
      .onSuccess(context: self) { me, value in
        me._producer.update(value)
      }
      
    } else {
      binding.feedback?.log?("refreshing")
      let value = binding.getter()
        .onSuccess { _producer.update($0) }
      return .completed(value)
      
    }
  }
}
