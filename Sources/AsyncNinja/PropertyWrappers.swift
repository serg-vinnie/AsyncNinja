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

@propertyWrapper public struct OptionalProducer<Value> {
  public var wrappedValue : Value? {
    set {
      let p = _producer
      DispatchQueue.main.async {
        if let v = newValue {
          p.update(v)
        }
      }
    }
    get {
      _producer._bufferedUpdates.last
    }
  }
  
  /// The property that can be accessed with the `$` syntax and allows access to the `Channel`
  public var projectedValue: Channel<Value, Void> { get { return _producer } }
  
  private let _producer : Producer<Value, Void>
  private let _refresher : Refresher<Value>
  
  @discardableResult
  public func refresh() -> Future<Value> { _refresher.refresh() }
  
  /// Initialize the storage of the Published property as well as the corresponding `Publisher`.
  public init(wrappedValue: Value?, _ getter: (()->R<Value>)? = nil) {
    let _p : Producer<Value, Void>
    
    if let v = wrappedValue {
      _p = Producer<Value,Void>(bufferSize: 1, bufferedUpdates: [v])
    } else {
      _p = Producer<Value,Void>(bufferSize: 1)
    }
    
    _producer = _p
    _refresher = .init(producer: _p, getter: getter)
  }
}

class Refresher<Value> : ExecutionContext, ReleasePoolOwner {
  public var executor    = Executor.init(queue: DispatchQueue.global(qos: .userInteractive))
  public let releasePool = ReleasePool()
  
  private let _producer : Producer<Value, Void>
  private let _getter : (()->R<Value>)?
  
  init(producer: Producer<Value, Void>, getter: (() -> R<Value>)?) {
    self._producer = producer
    self._getter = getter
  }
  
  func refresh() -> Future<Value> {
    if let getter = _getter {
      return self.promise { me, promise  in
        let val = getter()
        promise.complete(val)
      }
      .onSuccess(context: self) { me, value in
        me._producer.update(value)
      }
    } else {
      return .failed(WTF("_getter == nil"))
    }
  }
}
