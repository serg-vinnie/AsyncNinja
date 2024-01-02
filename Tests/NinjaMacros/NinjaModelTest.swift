import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(NinjaMacros)
import NinjaMacros

let testMacros: [String: Macro.Type] = [
    "ninjaModel": NinjaModelMacro.self,
    "demoMacro" : DemoMacro.self
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
    
    func testDemo() throws {
        let classDeclaration =  """
                                class Test {
                                var foo = "Foo"
                                func bar(_ v: Int, name: String) -> String { "" }
                                func bbar() -> (Int,String)->String
                                }
                                """
        
        let targetDeclaration = """
                                class Test2 { /* 
                                VAR  var foo = "Foo"
                                FUNC (Int,String)->String
                                FUNC ()->(Int,String)->String */
                                }
                                """
        
#if canImport(NinjaMacros)
        assertMacroExpansion(
            "@demoMacro\n\(classDeclaration)",
            expandedSource: """
                            \(classDeclaration)
                            
                            \(targetDeclaration)
                            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
