//
//  Array.swift
//  AsyncNinja
//
//  Created by loki on 09.04.2021.
//

import Foundation

public func future<T>(result: Result<T,Error>) -> Future<T> {
    future(value: result)
}

public extension Array {
    func reduce<A>(_ a: A, _ block: @escaping (A, Element) -> Future<A>) -> Future<A> {
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

    func flatMap<T>(_ exe: Execution = .concurent(), _ block: @escaping (Element) -> Future<T>) -> Future<[T]> {
        switch exe {
        case .concurent(let c): return flatMap(concurrency:c, block)
        case .sequential: return flatMapSequential(block: block)
        }
    }
    
    private func flatMap<T>(concurrency: Concurrency, _ block: @escaping (Element) -> Future<T>) -> Future<[T]> {
        return promise(executor: .userInteractive) { promise in
            let _locking = makeLocking()
            var _idx = 0
            var _all = [T]()
            _all.reserveCapacity(self.count)
            let DISPATCH_GROUP = DispatchGroup()
            DISPATCH_GROUP.enter()
            
            for item in self {
                Executor.userInteractive.schedule { e in
                    switch block(item).wait() {
                    case .success(let s):
                        _locking.lock()
                        _idx += 1
                        _all.append(s)
                        
                        if _idx == self.count {
                            DISPATCH_GROUP.leave()
                        }
                        _locking.unlock()
                    case .failure(let err):
                        promise.fail(err)
                    }
                }
            }
            
            DISPATCH_GROUP.wait()
            promise.succeed(_all)
        }
    }
    
    private func flatMapSequential<T>(block: @escaping (Element) -> Future<T>) -> Future<[T]> {
        self.reduce(ArrayWrapper(self.count)) { a, e in
            block(e).map { a += $0 }
        }
        .map { $0.array }
    }
    
//    func flatMap<T>(block: @escaping (Element) -> Future<T>) -> Channel<T,Void> {
//        let producer = Producer<T,Void>()
//
//        Executor.userInteractive.schedule { executor in
//            for item in self {
//                switch block(item).wait() {
//                case .success(let s):   producer.update(s)
//                case .failure(let err): producer.fail(err)
//                }
//            }
//            producer.succeed(())
//        }
//
//        return producer
//    }
    
    func flatMapToChannel<T,C:ExecutionContext>(
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
    
    // delete this function
    func aggregateFuture<Value>() -> Future<[Value]> where Element == Future<Value>{
        self.flatMapSequential { $0 }
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
}
