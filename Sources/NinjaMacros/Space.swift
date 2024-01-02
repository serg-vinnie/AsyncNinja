
import Foundation
import SwiftSyntax
import Essentials

struct SpaceID {
    let id : String
}

protocol AnySpace {
    var spaces  : [AnySpace]    { get }
    var mappers : [AnyMapper]      { get }
}

struct Space<SyntaxType: SyntaxProtocol> : AnySpace {
    var spaces: [AnySpace] {
        return SpacesExtractor(viewMode: .fixedUp).extract(syntax)
    }
    
    var mappers: [AnyMapper] {
        return []
    }
    
    let syntax: SyntaxType
}

class SpacesExtractor: SyntaxVisitor {
    var structs:    [StructDeclSyntax] = []
    var classes:    [ClassDeclSyntax] = []
    var protocols:  [ProtocolDeclSyntax] = []
    var extensions: [ExtensionDeclSyntax] = []
    
    func extract<SyntaxType: SyntaxProtocol>( _ syntax: SyntaxType) -> [AnySpace] {
        self.walk(syntax)
        return [structs.map { Space(syntax: $0) as AnySpace },
                classes.map { Space(syntax: $0) as AnySpace},
                protocols.map { Space(syntax: $0) as AnySpace},
                extensions.map { Space(syntax: $0) as AnySpace}]
            .flatMap { $0 }
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        structs.append(node)
        return .skipChildren
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        classes.append(node)
        return .skipChildren
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        protocols.append(node)
        return .skipChildren
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        extensions.append(node)
        return .skipChildren
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
