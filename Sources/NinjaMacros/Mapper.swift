
import Foundation
import SwiftSyntax
import Essentials

struct MapperID {
    let id : String
}

struct Mapper {
    let id : MapperID
    let declarations : [MapperDeclaration]
    
    var input : SpaceID { SpaceID(id: "Swift") }
    var output: SpaceID { SpaceID(id: "Void") }
}

enum MapperDeclaration {
    case Function(FunctionDeclSyntax)
    case Variable(VariableDeclSyntax)
}

class MappersExtractor: SyntaxVisitor {
    var funcs:    [FunctionDeclSyntax] = []
    var vars:     [VariableDeclSyntax] = []
    
    func extract<SyntaxType: SyntaxProtocol>( _ syntax: SyntaxType) -> [MapperDeclaration] {
        self.walk(syntax)
        return [funcs.map { MapperDeclaration.Function($0) },
                vars.map { MapperDeclaration.Variable($0) }]
            .flatMap { $0 }
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        vars.append(node)
        return .skipChildren
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        funcs.append(node)
        return .skipChildren
    }
}
