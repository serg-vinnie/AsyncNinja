//
//  EventSource_Folding.swift
//  AsyncNinja
//
//  Created by loki on 21.03.2021.
//

import Foundation

///
///  Channel
///

public extension Channel {
    func reduce<Accum>(_ a: Accum, _ block: @escaping (Accum, Update) -> Accum) -> Future<Accum> {
        return promise(executor: .userInteractive) { promise in
            let (updates, completion) = self.waitForAll()
            
            switch completion {
            case .success(_):
                var accum = a
                for item in updates {
                    accum = block(accum, item)
                }
                promise.succeed(accum)
            case .failure(let error):
                promise.fail(error)
            }
        }
    }

    
    func reduce<Accum>(_ a: Accum, block: @escaping (Accum, Update) -> Future<Accum>) -> Future<Accum> {
        return promise(executor: .userInteractive) { promise in
            let (updates, completion) = self.waitForAll()
            
            switch completion {
            case .success(_):
                promise.complete(updates
                                    .reduce(a, block)
                                    .wait())
            case .failure(let error):
                promise.fail(error)
            }
        }
    }
    
    func foldr<Accum>(_ a: Accum, _ block: @escaping (Accum, Update) -> Accum) -> Channel<Accum, Success> {
        return producer(executor: .userInteractive) { producer in
          var a = a
          self.onUpdate { upd in
            a = block(a,upd)
            producer.update(a)
          }.onComplete {
            producer.complete($0)
          }
      }
    }
}

public protocol Accumulator {
  static func + (lhs: Self, rhs: Self) -> Self
}

public extension Array {
  func foldr<Accum : Accumulator>(_ a: Accum, executor: Executor = .userInteractive, _ block: @escaping (Accum, Element) -> Channel<Accum, Void>) -> Channel<Accum, Void> {
    return producer(executor: executor) { producer in
      var accum = a
      let exe : Executor = .serialUnique
      for item in self {
        let r = block(accum, item)
          .onUpdate(executor: exe) { acc in
            accum = accum + acc
            producer.update(accum)
          }.wait()
        
        if case .failure(let error) = r {
          producer.fail(error)
        }
      }
      producer.succeed(())
    }
  }
}

///
///  Cursor
///


private extension Producer where Success == Void {
    func update<Cursor>(element: Element?, completion: Result<Cursor?, Error>) -> Cursor? {
        if let element = element {
            update(element)
        }
        if let error = completion.maybeFailure {
            self.fail(error)
            return nil
        }
        guard let cursor = completion.maybeSuccess else {
            succeed()
            return nil
        }

        return cursor
    }
}

public func cursor<Cursor,U>(executor: Executor = .userInteractive, cursor: Cursor, block: @escaping (Cursor) -> Channel<U, Cursor?>) -> Channel<[U],Void> {
  let producer = Producer<[U],Void>()
  
  executor.schedule { _ in
    var result = block(cursor).waitForAll()
    var element = result.updates.count > 0 ? result.updates : nil
    while let cursor = producer.update(element: element, completion: result.completion) {
      result = block(cursor).waitForAll()
      element = result.updates.count > 0 ? result.updates : nil
    }
    producer.succeed()
  }
  
  return producer
}

public func cursor<Cursor,C:ExecutionContext,U>(context: C, cursor: Cursor, block: @escaping (C, Cursor) -> Channel<U, Cursor?>) -> Channel<[U],Void> {
  let producer = Producer<[U],Void>()
  
  context.executor.schedule { _ in
    var result = block(context, cursor).waitForAll()
    var element = result.updates.count > 0 ? result.updates : nil
    while let cursor = producer.update(element: element, completion: result.completion) {
      result = block(context, cursor).waitForAll()
      element = result.updates.count > 0 ? result.updates : nil
    }
  }
  
  return producer
}

///
///  Array
///

