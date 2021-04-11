//
//  Array.swift
//  AsyncNinja
//
//  Created by loki on 09.04.2021.
//

import Foundation

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

public extension Array {
    func aggregateFuture<Value>() -> Future<[Value]> where Element == Future<Value>{
        self.flatMapFuture { $0 }
            .reduce( ArrayWrapper(self.count), += )
            .map(executor: .immediate) { $0.array }
    }
}
