//
//  Copyright (c) 2016 Anton Mironov
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

import Dispatch

/// ThreadSafeContainer is a data structure that has head and can change this head with thread safety.
/// Current implementation is lock-free that has to be perfect for quick and often updates.
typealias ThreadSafeContainer<Item : AnyObject> = LockFreeThreadSafeContainer<Item>

protocol _ThreadSafeContainer : class {
  associatedtype Item: AnyObject
  var head: Item? { get }

  @discardableResult
  func updateHead(_ block: (Item?) -> HeadChange<Item>) -> (oldHead: Item?, newHead: Item?)
}

enum HeadChange<T : AnyObject> {
  case keep
  case remove
  case replace(T)
}
