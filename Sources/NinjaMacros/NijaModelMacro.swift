import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import AsyncNinja
import SwiftUI


@attached(extension, conformances: ExecutionContext, ReleasePoolOwner, ObservableObject)
@attached(member, names: named(executor), named(releasePool))
public macro ninjaModel() = #externalMacro(module: "NinjaMacros", type: "NinjaModelMacro")

public struct NinjaModelMacro: ExtensionMacro, MemberMacro {    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext)
    throws -> [SwiftSyntax.DeclSyntax] {
        ["public let executor    = Executor.init(queue: DispatchQueue.main)",
         "public let releasePool = ReleasePool()"]
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        try [ExtensionDeclSyntax("extension \(type.trimmed): ExecutionContext, ReleasePoolOwner, ObservableObject {}")]
    }
    
    
}

@main
struct boilerplatePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        NinjaModelMacro.self,
    ]
}
