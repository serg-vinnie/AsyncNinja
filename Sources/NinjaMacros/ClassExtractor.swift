
import Foundation
import SwiftSyntax
import Essentials

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
