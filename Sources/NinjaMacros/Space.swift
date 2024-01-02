
import Foundation
import SwiftSyntax
import Essentials

struct SpaceID {
    let id : String
}

struct SwiftFile {
    let spaces : [Space]
    let mappers : [Mapper]
}

struct Space {
    let id: SpaceID
    let declarations: [SpaceDeclaration]
}

enum SpaceDeclaration {
    case Struct(StructDeclSyntax)
    case Class(ClassDeclSyntax)
    case Proto(ProtocolDeclSyntax)
    case Extension(ExtensionDeclSyntax)
    case Enum(EnumDeclSyntax)
}

class SpacesExtractor: SyntaxVisitor {
    var structs:    [StructDeclSyntax] = []
    var classes:    [ClassDeclSyntax] = []
    var protocols:  [ProtocolDeclSyntax] = []
    var extensions: [ExtensionDeclSyntax] = []
    var enums:      [EnumDeclSyntax] = []
    
    func extract<SyntaxType: SyntaxProtocol>( _ syntax: SyntaxType) -> [SpaceDeclaration] {
        self.walk(syntax)
        return [structs.map { SpaceDeclaration.Struct($0) },
                classes.map { SpaceDeclaration.Class($0) },
                protocols.map { SpaceDeclaration.Proto($0) },
                extensions.map { SpaceDeclaration.Extension($0) },
                enums.map { SpaceDeclaration.Enum($0) }]
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
    
    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        enums.append(node)
        return .skipChildren
    }
}


