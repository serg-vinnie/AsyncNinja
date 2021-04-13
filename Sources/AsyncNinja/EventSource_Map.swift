//
//  Copyright (c) 2016-2017 Anton Mironov
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

// MARK: - whole channel transformations
public extension EventSource {

  /// Applies transformation to the whole channel. `map` methods
  /// are more convenient if you want to transform updates values only.
  ///
  /// - Parameters:
  ///   - context: `ExectionContext` to apply transformation in
  ///   - executor: override of `ExecutionContext`s executor.
  ///     Keep default value of the argument unless you need to override
  ///     an executor provided by the context
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned primitive
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply
  ///   - strongContext: context restored from weak reference to specified context
  ///   - value: `ChannelValue` to transform. May be either update or completion
  /// - Returns: transformed channel
  func mapEvent<P, S, C: ExecutionContext>(
    context: C,
    executor: Executor? = nil,
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ strongContext: C, _ event: Event) throws -> ChannelEvent<P, S>
    ) -> Channel<P, S> {
    return makeProducer(
      context: context,
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize,
      traceID: traceID?.appending("∙mapEvent")
    ) { (context, event, producer, originalExecutor) in
      let transformedEvent = try transform(context, event)
      producer.value?.traceID?._asyncNinja_log("mapping from \(event)")
      producer.value?.traceID?._asyncNinja_log("mapping to \(transformedEvent)")
      producer.value?.post(transformedEvent, from: originalExecutor)
    }
  }

  /// Applies transformation to the whole channel. `map` methods
  /// are more convenient if you want to transform updates values only.
  ///
  /// - Parameters:
  ///   - executor: to execute transform on
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned primitive
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply
  ///   - value: `ChannelValue` to transform. May be either update or completion
  /// - Returns: transformed channel
  func mapEvent<P, S>(
    executor: Executor = .primary,
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ event: Event) throws -> ChannelEvent<P, S>
    ) -> Channel<P, S> {
    return makeProducer(
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize,
      traceID: traceID?.appending("∙mapEvent")
    ) { (event, producer, originalExecutor) in
      let transformedEvent = try transform(event)
      producer.value?.traceID?._asyncNinja_log("mapping from \(event)")
      producer.value?.traceID?._asyncNinja_log("mapping to \(transformedEvent)")
      producer.value?.post(transformedEvent, from: originalExecutor)
    }
  }
}

// MARK: - updates only transformations

public extension EventSource {

  /// Applies transformation to update values of the channel.
  /// `map` methods are more convenient if you want to transform
  /// both updates and completion
  ///
  /// - Parameters:
  ///   - context: `ExectionContext` to apply transformation in
  ///   - executor: override of `ExecutionContext`s executor.
  ///     Keep default value of the argument unless you need to override
  ///     an executor provided by the context
  ///   - cancellationToken: `CancellationToken` to use. Keep default value
  ///     of the argument unless you need an extended cancellation options
  ///     of the returned channel
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply
  ///   - strongContext: context restored from weak reference to specified context
  ///   - update: `Update` to transform
  /// - Returns: transformed channel
  func map<P, C: ExecutionContext>(
    context: C,
    executor: Executor? = nil,
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ strongContext: C, _ update: Update) throws -> P
    ) -> Channel<P, Success> {
    // Test: EventSource_MapTests.testMapContextual

    return makeProducer(
      context: context,
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize,
      traceID: traceID?.appending("∙map")
    ) { (context, event, producer, originalExecutor) in
      switch event {
      case .update(let update):
        let transformedValue = try transform(context, update)
        producer.value?.traceID?._asyncNinja_log("mapping from \(update)")
        producer.value?.traceID?._asyncNinja_log("mapping to \(transformedValue)")
        producer.value?.update(transformedValue, from: originalExecutor)
      case .completion(let completion):
        producer.value?.traceID?._asyncNinja_log("completion with \(completion)")
        producer.value?.complete(completion, from: originalExecutor)
      }
    }
  }

  /// Applies transformation to update values of the channel.
  /// `map` methods are more convenient if you want to transform
  /// both updates and completion
  ///
  /// - Parameters:
  ///   - executor: to execute transform on
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned primitive
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply
  ///   - update: `Update` to transform
  /// - Returns: transformed channel
  func map<P>(
    executor: Executor = .primary,
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ update: Update) throws -> P
    ) -> Channel<P, Success> {
    // Test: EventSource_MapTests.testMap
    
    traceID?._asyncNinja_log("apply mapping")
    
    return makeProducer(
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize,
      traceID: traceID?.appending("∙map")
    ) { (event, producer, originalExecutor) in
      
      switch event {
      case .update(let update):
        
        let transformedValue = try transform(update)
        producer.value?.traceID?._asyncNinja_log("mapping from \(update)")
        producer.value?.traceID?._asyncNinja_log("mapping to \(transformedValue)")
        
        producer.value?.update(transformedValue, from: originalExecutor)
      case .completion(let completion):
        producer.value?.traceID?._asyncNinja_log("completion with \(completion)")
        producer.value?.complete(completion, from: originalExecutor)
      }
    }
  }
}

// MARK: - updates only flattening transformations

public extension EventSource {
    /// Applies transformation to update values of the channel.
    ///
    /// - Parameters:
    ///   - context: `ExectionContext` to apply transformation in
    ///   - catch: Error property on the context
    ///   - transform: to apply. Sequence returned from transform
    ///     will be treated as multiple period values
    ///   - strongContext: context restored from weak reference to specified context
    ///   - update: `Update` to transform
    /// - Returns: transformed channel
    func flatMap<FC, C: ExecutionContext>(
      context: C,
      `catch` errorKeyPath: ReferenceWritableKeyPath<C, Error?>? = nil,
      _ transform: @escaping (_ strongContext: C, _ update: Update) -> Future<FC>
    ) -> Channel<FC, Success> {
      // Test: EventSource_MapTests.testFlatMapArrayContextual

      traceID?._asyncNinja_log("apply flatMapping")
        
      return makeProducer(
        context: context,
        executor: .serialUnique,
        pure: true,
        cancellationToken: nil,
        bufferSize: .default,
        traceID: traceID?.appending("∙flatMapp")
      ) { (context, event, producer, originalExecutor) in
        switch event {
        case .update(let update):
          producer.value?.traceID?._asyncNinja_log("flatMapping update \(update)")
            
          switch transform(context, update).wait() {
          case .success(let success):
            producer.value?.update(success, from: originalExecutor)
          case .failure(let error):
            producer.value?.fail(error)
          }
          
          //
          
        case .completion(let completion):
            producer.value?.traceID?._asyncNinja_log("completion with \(completion)")
              
          switch completion {
          case .success(let success):
              producer.value?.succeed(success)
          case .failure(let error):
            if let path = errorKeyPath {
              context[keyPath: path] = error
            } else {
              producer.value?.fail(error)
            }
          }
        }
      }
    }
    /// Applies transformation to update values of the channel.
    ///
    /// - Parameters:
    ///   - context: `ExectionContext` to apply transformation in
    ///   - catch: Error property on the context
    ///   - executor: override of `ExecutionContext`s executor.
    ///     Keep default value of the argument unless you need
    ///     to override an executor provided by the context
    ///   - cancellationToken: `CancellationToken` to use.
    ///     Keep default value of the argument unless you need
    ///     an extended cancellation options of returned primitive
    ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
    ///     Keep default value of the argument unless you need
    ///     an extended buffering options of returned channel
    ///   - transform: to apply. Sequence returned from transform
    ///     will be treated as multiple period values
    ///   - strongContext: context restored from weak reference to specified context
    ///   - update: `Update` to transform
    /// - Returns: transformed channel
    func flatMap<ES: EventSource, C: ExecutionContext>(
      context: C,
      `catch` errorKeyPath: ReferenceWritableKeyPath<C, Error?>? = nil,
      executor: Executor? = .serialUnique, // temp solution for flatMap bcs 1. conqurent executor will cause loss of updates bug 2. serial executre can cause deadlock
      pure: Bool = true,
      cancellationToken: CancellationToken? = nil,
      bufferSize: DerivedChannelBufferSize = .default,
      _ transform: @escaping (_ strongContext: C, _ update: Update) throws -> ES 
      ) -> Channel<ES.Update, Success> where ES.Update == ES.Element{
      // Test: EventSource_MapTests.testFlatMapArrayContextual

      traceID?._asyncNinja_log("apply flatMapping")
      
      return makeProducer(
        context: context,
        executor: executor,
        pure: pure,
        cancellationToken: cancellationToken,
        bufferSize: bufferSize,
        traceID: traceID?.appending("∙flatMapp")
      ) { (context, event, producer, originalExecutor) in
        switch event {
        case .update(let update):
          producer.value?.traceID?._asyncNinja_log("flatMapping update \(update)")
          producer.value?.update(try transform(context, update), from: originalExecutor)
          
        case .completion(let completion):
            producer.value?.traceID?._asyncNinja_log("completion with \(completion)")
              
          switch completion {
          case .success(let success):
              producer.value?.succeed(success)
          case .failure(let error):
            if let path = errorKeyPath {
              context[keyPath: path] = error
            } else {
              producer.value?.fail(error)
            }
          }
        }
      }
    }


  /// Applies transformation to update values of the channel.
  ///
  /// - Parameters:
  ///   - context: `ExectionContext` to apply transformation in
  ///   - executor: override of `ExecutionContext`s executor.
  ///     Keep default value of the argument unless you need to override
  ///     an executor provided by the context
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned primitive
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply. Nil returned from transform will not produce update value
  ///   - strongContext: context restored from weak reference to specified context
  ///   - update: `Update` to transform
  /// - Returns: transformed channel
  func flatMap<P, C: ExecutionContext>(
    context: C,
    executor: Executor? = .serialUnique, // temp solution for flatMap bcs 1. conqurent executor will cause loss of updates bug 2. serial executre can cause deadlock
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ strongContext: C, _ update: Update) throws -> P?
    ) -> Channel<P, Success> {
    // Test: EventSource_MapTests.testFlatMapOptionalContextual

    traceID?._asyncNinja_log("apply flatMapping")
    
    return makeProducer(
      context: context,
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize,
      traceID: traceID?.appending("∙flatMapp")
    ) { (context, event, producer, originalExecutor) in
      switch event {
      case .update(let update):
        if let transformedValue = try transform(context, update) {
          producer.value?.traceID?._asyncNinja_log("flatMapping from \(update)")
          producer.value?.traceID?._asyncNinja_log("flatMapping to \(transformedValue)")
          producer.value?.update(transformedValue, from: originalExecutor)
        }
      case .completion(let completion):
        producer.value?.traceID?._asyncNinja_log("completion with \(completion)")
        producer.value?.complete(completion, from: originalExecutor)
      }
    }
  }

  /// Applies transformation to update values of the channel.
  ///
  /// - Parameters:
  ///   - executor: to execute transform on
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned primitive
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply. Nil returned from transform will not produce update value
  ///   - update: `Update` to transform
  /// - Returns: transformed channel
  func flatMap<P>(
    executor: Executor = .serialUnique, // temp solution for flatMap bcs 1. conqurent executor will cause loss of updates bug 2. serial executre can cause deadlock
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ update: Update) throws -> P?
    ) -> Channel<P, Success> {
    // Test: EventSource_MapTests.testFlatMapOptional

    return makeProducer(
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize,
      traceID: traceID?.appending("∙flatMapp")
    ) { (event, producer, originalExecutor) in
      switch event {
      case .update(let update):
        if let transformedValue = try transform(update) {
          producer.value?.traceID?._asyncNinja_log("flatMapping update \(update)")
          producer.value?.update(transformedValue, from: originalExecutor)
        }
      case .completion(let completion):
        producer.value?.traceID?._asyncNinja_log("completion with \(completion)")
        producer.value?.complete(completion, from: originalExecutor)
      }
    }
  }

  /// Applies transformation to update values of the channel.
  ///
  /// - Parameters:
  ///   - context: `ExectionContext` to apply transformation in
  ///   - executor: override of `ExecutionContext`s executor.
  ///     Keep default value of the argument unless you need
  ///     to override an executor provided by the context
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned primitive
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply. Sequence returned from transform
  ///     will be treated as multiple period values
  ///   - strongContext: context restored from weak reference to specified context
  ///   - update: `Update` to transform
  /// - Returns: transformed channel
  func flatMap<ES: EventSource, C: ExecutionContext>(
    context: C,
    executor: Executor? = .serialUnique, // temp solution for flatMap bcs 1. conqurent executor will cause loss of updates bug 2. serial executre can cause deadlock
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ strongContext: C, _ update: Update) throws -> ES
    ) -> Channel<ES.Update, Success> where ES.Update == ES.Element{
    // Test: EventSource_MapTests.testFlatMapArrayContextual

    traceID?._asyncNinja_log("apply flatMapping")
    
    return makeProducer(
      context: context,
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize,
      traceID: traceID?.appending("∙flatMapp")
    ) { (context, event, producer, originalExecutor) in
      switch event {
      case .update(let update):
        producer.value?.traceID?._asyncNinja_log("flatMapping update \(update)")
        producer.value?.update(try transform(context, update), from: originalExecutor)
        
      case .completion(let completion):
        producer.value?.traceID?._asyncNinja_log("completion with \(completion)")
        producer.value?.complete(completion, from: originalExecutor)
      }
    }
  }

  /// Applies transformation to update values of the channel.
  ///
  /// - Parameters:
  ///   - executor: to execute transform on
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned primitive
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply. Sequence returned from transform
  ///     will be treated as multiple period values
  ///   - update: `Update` to transform
  /// - Returns: transformed channel
  func flatMap<ES: EventSource>(
    executor: Executor = .serialUnique, // temp solution for flatMap bcs 1. conqurent executor will cause loss of updates bug 2. serial executre can cause deadlock
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ update: Update) throws -> ES
    ) -> Channel<ES.Iterator.Element, Success> {
    // Test: EventSource_MapTests.testFlatMapArray

    return makeProducer(
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize,
      traceID: traceID?.appending("∙flatMapp")
    ) { (event, producer, originalExecutor) in
      switch event {
      case .update(let update):
        producer.value?.traceID?._asyncNinja_log("flatMapping from \(update)")
        producer.value?.update(try transform(update), from: originalExecutor)
      case .completion(let completion):
        producer.value?.traceID?._asyncNinja_log("completion with \(completion)")
        producer.value?.complete(completion, from: originalExecutor)
      }
    }
  }
  
  /// Applies transformation to update values of the channel.
  ///
  /// - Parameters:
  ///   - transform: to apply. Sequence returned from transform
  /// - Returns: transformed channel
  func flatMap<C: Completing>(
    _ transform: @escaping (_ update: Update) -> C
  ) -> Channel<C.Success, Success> {
    // Test: EventSource_MapTests.testFlatMapArray

    return makeProducer(
      executor: .serialUnique,
      pure: true,
      cancellationToken: nil,
      bufferSize: .default,
      traceID: traceID?.appending("∙flatMapp")
    ) { (event, producer, originalExecutor) in
      switch event {
      case .update(let update):
        producer.value?.traceID?._asyncNinja_log("flatMapping from \(update)")
        
        switch transform(update).wait() {
        case .success(let success):
          producer.value?.update(success, from: originalExecutor)
        case .failure(let error):
          producer.value?.fail(error)
        }
        
      case .completion(let completion):
        producer.value?.traceID?._asyncNinja_log("completion with \(completion)")
        producer.value?.complete(completion, from: originalExecutor)
      }
    }
  }

}

// MARK: - map completion

public extension EventSource {

  /// Applies transformation to a completion of EventSource.
  ///
  /// - Parameters:
  ///   - context: `ExectionContext` to apply transformation in
  ///   - executor: override of `ExecutionContext`s executor.
  ///     Keep default value of the argument unless you need to override
  ///     an executor provided by the context
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned primitive
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply
  ///   - strongContext: context restored from weak reference to specified context
  ///   - value: `ChannelValue` to transform. May be either update or completion
  /// - Returns: transformed channel
  func mapCompletion<Transformed, C: ExecutionContext>(
    context: C,
    executor: Executor? = nil,
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (C, Fallible<Success>) throws -> Transformed
    ) -> Channel<Update, Transformed> {
    return makeProducer(
      context: context,
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize,
      traceID: traceID?.appending("∙mapCompletion")
    ) { (context, event, producer, originalExecutor) in
      switch event {
      case let .update(update):
        producer.value?.traceID?._asyncNinja_log("update \(update)")
        producer.value?.update(update, from: originalExecutor)
      case let .completion(completion):
        let transformedCompletion = fallible { try transform(context, completion) }
        producer.value?.traceID?._asyncNinja_log("completion \(completion)")
        producer.value?.traceID?._asyncNinja_log("transformedCompletion \(transformedCompletion)")
        producer.value?.complete(transformedCompletion, from: originalExecutor)
      }
    }
  }

  /// Applies transformation to a success of EventSource.
  ///
  /// - Parameters:
  ///   - context: `ExectionContext` to apply transformation in
  ///   - executor: override of `ExecutionContext`s executor.
  ///     Keep default value of the argument unless you need to override
  ///     an executor provided by the context
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned primitive
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply
  ///   - strongContext: context restored from weak reference to specified context
  ///   - value: `ChannelValue` to transform. May be either update or completion
  /// - Returns: transformed channel
  func mapSuccess<Transformed, C: ExecutionContext>(
    context: C,
    executor: Executor? = nil,
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (C, Success) throws -> Transformed
    ) -> Channel<Update, Transformed> {
    return mapCompletion(
      context: context,
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize
    ) { (context, value) -> Transformed in
      let success = try value.get()
      return try transform(context, success)
    }
  }

  /// Applies transformation to a completion of EventSource.
  ///
  /// - Parameters:
  ///   - executor: to execute transform on
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned primitive
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply
  ///   - value: `ChannelValue` to transform. May be either update or completion
  /// - Returns: transformed channel
  func mapCompletion<Transformed>(
    executor: Executor = .primary,
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (Fallible<Success>) throws -> Transformed
    ) -> Channel<Update, Transformed> {
    return makeProducer(
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize,
      traceID: traceID?.appending("∙mapCompletion")
    ) { (event, producer, originalExecutor) in
      switch event {
      case let .update(update):
        producer.value?.update(update, from: originalExecutor)
        producer.value?.traceID?._asyncNinja_log("update \(update)")
      case let .completion(completion):
        let transformedCompletion = fallible { try transform(completion) }
        producer.value?.traceID?._asyncNinja_log("completion \(completion)")
        producer.value?.traceID?._asyncNinja_log("transformedCompletion \(transformedCompletion)")
        producer.value?.complete(transformedCompletion, from: originalExecutor)
      }
    }
  }

  /// Applies transformation to a success of EventSource.
  ///
  /// - Parameters:
  ///   - executor: to execute transform on
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned primitive
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply
  ///   - value: `ChannelValue` to transform. May be either update or completion
  /// - Returns: transformed channel
  func mapSuccess<Transformed>(
    executor: Executor = .primary,
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (Success) throws -> Transformed
    ) -> Channel<Update, Transformed> {
    return mapCompletion(
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize
    ) { (value) -> Transformed in
      let transformedValue = try value.get()
      return try transform(transformedValue)
    }
  }
}

// MARK: - convenient transformations

public extension EventSource {

  /// Filters update values of the channel
  ///
  ///   - context: `ExectionContext` to apply predicate in
  ///   - executor: override of `ExecutionContext`s executor.
  ///     Keep default value of the argument unless you need to override
  ///     an executor provided by the context
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned primitive
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - predicate: to apply
  ///   - strongContext: context restored from weak reference to specified context
  ///   - update: `Update` to transform
  /// - Returns: filtered transform
  func filter<C: ExecutionContext>(
    context: C,
    executor: Executor? = nil,
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ predicate: @escaping (_ strongContext: C, _ update: Update) throws -> Bool
    ) -> Channel<Update, Success> {
    // Test: EventSource_MapTests.testFilterContextual

    traceID?._asyncNinja_log("apply filtering")
    
    return makeProducer(
      context: context,
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize,
      traceID: traceID?.appending("∙filter")
    ) { (context, event, producer, originalExecutor) in
      switch event {
      case .update(let update):
        do {
          if try predicate(context, update) {
            producer.value?.traceID?._asyncNinja_log("update \(update)")
            producer.value?.update(update, from: originalExecutor)
          } else {
            producer.value?.traceID?._asyncNinja_log("skipping update \(update)")
          }
        } catch { producer.value?.fail(error, from: originalExecutor) }
      case .completion(let completion):
        producer.value?.traceID?._asyncNinja_log("completion \(completion)")
        producer.value?.complete(completion, from: originalExecutor)
      }
    }
  }

  /// Filters update values of the channel
  ///
  ///   - executor: to execute transform on
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned primitive
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - predicate: to apply
  ///   - update: `Update` to transform
  /// - Returns: filtered transform
  func filter(
    executor: Executor = .primary,
    pure: Bool = true,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ predicate: @escaping (_ update: Update) throws -> Bool
    ) -> Channel<Update, Success> {
    // Test: EventSource_MapTests.testFilter

    traceID?._asyncNinja_log("apply filtering")
    
    return makeProducer(
      executor: executor,
      pure: pure,
      cancellationToken: cancellationToken,
      bufferSize: bufferSize,
      traceID: traceID?.appending("∙filter")
    ) { (event, producer, originalExecutor) in
      switch event {
      case .update(let update):
        do {
          if try predicate(update) {
            producer.value?.traceID?._asyncNinja_log("update \(update)")
            producer.value?.update(update, from: originalExecutor)
          } else {
            producer.value?.traceID?._asyncNinja_log("skipping update \(update)")
          }
        } catch { producer.value?.fail(error, from: originalExecutor) }
      case .completion(let completion):
        producer.value?.traceID?._asyncNinja_log("completion \(completion)")
        producer.value?.complete(completion, from: originalExecutor)
      }
    }
  }
}

public extension EventSource where Update: _Fallible {
  /// makes channel of unsafely unwrapped optional Updates
  var unsafelyUnwrapped: Channel<Update.Success, Success> {
    return map(executor: .immediate) { $0.maybeSuccess! }
  }

  /// makes channel of unsafely unwrapped optional Updates
  var unwrapped: Channel<Update.Success, Success> {
    func transform(update: Update) throws -> Update.Success {
      return try update.get()
    }

    return map(executor: .immediate, transform)
  }
}
