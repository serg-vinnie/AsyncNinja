import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(NinjaMacros)
import NinjaMacros

let testMacros: [String: Macro.Type] = [
    "ninjaModel": NinjaModelMacro.self,
]
#endif

final class boilerplateTests: XCTestCase {
    func testMacro() throws {
#if canImport(NinjaMacros)
        assertMacroExpansion(
            """
            @ninjaModel
            class Test {}
            """,
            expandedSource: """
                            class Test {
                            
                                public let executor    = Executor.init(queue: DispatchQueue.main)
                            
                                public let releasePool = ReleasePool()}
                            
                            extension Test: ExecutionContext, ReleasePoolOwner, ObservableObject {
                            }
                            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
