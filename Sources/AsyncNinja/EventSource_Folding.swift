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
