//
//  Array.swift
//  AsyncNinja
//
//  Created by loki on 09.04.2021.
//

import Foundation

public extension Array {
    func reduce<Accum>(_ a: Accum, block: @escaping (Accum, Element) -> Future<Accum>) -> Future<Accum> {
        return promise(executor: .userInteractive) { promise in
            var _a = a
            for item in self {
                    switch block(_a, item).wait() {
                    case .success(let s):   _a = s
                    case .failure(let err): promise.fail(err)
                    }
            }
            promise.succeed(_a)
        }
    }
}


public extension Array {
  func flatMap<T>(block: @escaping (Element) -> Future<T>) -> Channel<T,Void> {
    let producer = Producer<T,Void>()
    
    Executor.userInteractive.schedule { executor in
      for item in self {
        switch block(item).wait() {
        case .success(let s):   producer.update(s)
        case .failure(let err): producer.fail(err)
        }
      }
      producer.succeed(())
    }
    
    return producer
  }
  
  func flatMap<T,C:ExecutionContext>(
    context: C,
    `catch` errorKeyPath: ReferenceWritableKeyPath<C, Error?>? = nil,
    block: @escaping (C, Element) -> Future<T>) -> Channel<T,Void>
  {
    let producer = Producer<T,Void>()
    
    Executor.userInteractive.schedule { executor in
      for item in self {
        switch block(context,item).wait() {
        case .success(let s):
          producer.update(s)
        case .failure(let error):
          producer.fail(error)
          
          if let path = errorKeyPath {
            context[keyPath: path] = error
          } else {
            producer.fail(error)
          }

        }
      }
      producer.succeed(())
    }
    
    return producer
  }
  
  func aggregateFuture<Value>() -> Future<[Value]> where Element == Future<Value>{
    self.flatMap { $0 }
      .reduce( ArrayWrapper(self.count), += )
      .map(executor: .immediate) { $0.array }
  }
  
  func aggregateFuture2<Value>() -> Future<[Value]> where Element == Future<Value> {
    self.reduce( ArrayWrapper(self.count)) { accum, element in
      element.map { accum += $0 }
    }.map(executor: .immediate) { $0.array }
  }
  
}

class ArrayWrapper<T> {
  var array : [T]
  init(_ reserve: Int) {
    array = [T]()
    array.reserveCapacity(reserve)
  }
  
  static func += (left: ArrayWrapper<T>, right: T) -> ArrayWrapper<T> {
    left.array.append(right)
    return left
  }
  
  static func += (left: ArrayWrapper<T>, right: [T]) -> ArrayWrapper<T> {
    left.array.append(contentsOf: right)
    return left
  }
}

extension Array {
  static func += (left: Self, right: Element) -> Self {
    var newArray = left
    newArray.append(right)
    return newArray
  }
  
  func aggregateFuture3<Value>() -> Future<[Value]> where Element == Future<Value>{
    self.flatMap { $0 }
      .reduce( [Value](), += )
  }
  
  func aggregateFuture4<Value>() -> Future<[Value]> where Element == Future<Value> {
    self.reduce( [Value]() ) { accum, element in
      element.map { accum += $0 }
    }
  }

}
