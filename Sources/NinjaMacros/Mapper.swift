
import Foundation
import SwiftSyntax
import Essentials

struct MapperID {
    let id : String
}

protocol AnyMapper {
    var input  : SpaceID { get }
    var output : SpaceID { get }
}

struct Mapper<SyntaxType: SyntaxProtocol>: AnyMapper {
    let syntax: SyntaxType
    
    var input : SpaceID { SpaceID(id: "Swift") }
    var output: SpaceID { SpaceID(id: "Swift") }
}

class MappersExtractor: SyntaxVisitor {
    var funcs:    [FunctionDeclSyntax] = []
    var vars:     [VariableDeclSyntax] = []
    
    func extract<SyntaxType: SyntaxProtocol>( _ syntax: SyntaxType) -> [AnySpace] {
        self.walk(syntax)
        return [funcs.map { Space(syntax: $0) as AnySpace }]
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
