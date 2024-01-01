import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


@attached(peer)
@attached(member, names: arbitrary)
public macro demoMacro() = #externalMacro(module: "NinjaMacros", type: "DemoMacro")

public struct DemoMacro: PeerMacro {
//    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
//                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
//                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
//        ["let name = \"Swift\""]
//    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        
        let classDecl = declaration.cast(ClassDeclSyntax.self)
        
        return ["class \(raw: classDecl.name.trimmed)2 {}"]
    }
    
}

extension FunctionDeclSyntax {
    var asFunctionTypeSyntax : FunctionTypeSyntax {
        let inputTypes = self.signature.parameterClause.parameters.map(\.type)
        let outputType = self.signature.returnClause?.type ?? TypeSyntax("Void")
        let tupleElements =
        TupleTypeElementListSyntax(inputTypes.map { TupleTypeElementSyntax(type: $0)} )
        return FunctionTypeSyntax(parameters: tupleElements, returnClause: ReturnClauseSyntax(type: outputType))
    }
}
