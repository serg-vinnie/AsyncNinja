//
//  Concurrency.swift
//  AsyncNinja
//
//  Created by loki on 16.04.2021.
//

import Foundation

public enum Concurrency {
  case unrestricted
  case restricted(Int)
  case auto
}

public enum Execution {
  case concurent(Concurrency = .auto)
  case sequential
}

extension Concurrency {
  func coresCount() -> Int {
    return ProcessInfo().processorCount
  }
  
  func maxThreads() -> Int {
    switch self {
    case .unrestricted:         return 64
    case .restricted(let n):    return n
    case .auto:                 return coresCount()
    }
  }
}

extension Execution {
  func maxThreads() -> Int {
    switch self {
    case .concurent(let c):     return c.maxThreads()
    case .sequential:           return 1
    }
  }
}
