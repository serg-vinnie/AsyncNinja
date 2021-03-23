//
//  EventSource_Folding.swift
//  AsyncNinja
//
//  Created by loki on 21.03.2021.
//

import Foundation

public extension EventSource {
    func foldr<Accum>(_ a: Accum, block: @escaping (Accum, Update) -> Future<Accum>) -> Future<Accum> {
        let promise = Promise<Accum>()
        var _a = a
        let exe2 = Executor.serialUnique // access _a only from this executor
        
        self.onUpdate(executor: .serialUnique) { element in
            block(_a, element)
                .onSuccess(executor: exe2) {
                  _a = $0
                }
                .onFailure(executor: exe2) {
                  promise.fail($0)
                }
        }.onSuccess(executor: exe2) { success in
            promise.succeed(_a)
        }
        
        return promise
    }
}

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

public extension Array {
    func foldr<Accum>(_ a: Accum, block: @escaping (Accum, Element) -> Future<Accum>) -> Future<Accum> {
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
    
    func flatMapFuture<T>(block: @escaping (Element) -> Future<T>) -> Channel<T,Void> {
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
    
    func flatMapFuture<T,C:ExecutionContext>(context: C, block: @escaping (C, Element) -> Future<T>) -> Channel<T,Void> {
        let producer = Producer<T,Void>()
        
        Executor.userInteractive.schedule { executor in
            for item in self {
                switch block(context,item).wait() {
                case .success(let s):   producer.update(s)
                case .failure(let err): producer.fail(err)
                }
            }
            producer.succeed(())
        }
        
        return producer
    }
}
