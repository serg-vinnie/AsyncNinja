import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


@attached(peer)
@attached(member, names: arbitrary)
public macro demoMacro() = #externalMacro(module: "NinjaMacros", type: "DemoMacro")

/***/
public struct DemoMacro: PeerMacro {
//    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
//                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
//                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
//        ["let name = \"Swift\""]
//    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        
        if let _protocol = declaration.as(ProtocolDeclSyntax.self) {
            
            
            return ["protocol \(raw: _protocol.name.trimmed)2 {}"]
        } else if let _class = declaration.as(ClassDeclSyntax.self) {
//            return []
            return ["class \(raw: _class.name.trimmed)2 { /* \n\(raw: ClassExtractor().extract(_class).joined(separator: "\n")) */ }"]
        }
        
        fatalError("unexpected declaration")
    }
    
}

extension FunctionDeclSyntax {
    var asFunctionTypeSyntax : FunctionTypeSyntax {
        let inputTypes = self.signature.parameterClause.parameters.map(\.type)
        let outputType = self.signature.returnClause?.type ?? TypeSyntax("Void")
        let tupleElements = //TupleTypeElementListSyntax(inputTypes.map { TupleTypeElementSyntax(type: $0)} )
        TupleTypeElementListSyntax {
            for t in inputTypes {
                TupleTypeElementSyntax(type: t)
            }
        }
        return FunctionTypeSyntax(parameters: tupleElements, returnClause: ReturnClauseSyntax(type: outputType))
    }
}

class ClassExtractor: SyntaxVisitor {
    var items: [String] = []
    
    init() {
        super.init(viewMode: .fixedUp)
    }
    
    func extract<SyntaxType: SyntaxProtocol>( _ syntax: SyntaxType) -> [String] {
        self.walk(syntax)
        return items
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        items.append("VAR  \(node.trimmedDescription)")
        return .skipChildren
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        items.append("FUNC \(node.asFunctionTypeSyntax.trimmedDescription)")
        return .skipChildren
    }
}
