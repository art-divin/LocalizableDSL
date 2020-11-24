//
//  EnumTree.swift
//  LocalizableDSL
//
//  Created by Ruslan Alikhamov on 17.09.2020.
//

import Foundation
import SwiftSyntax

struct EnumTree {
    
    var parent : EnumDeclSyntax
    var members : [ MemberDeclBlockSyntax ] = []
    var child : EnumDeclSyntax?
    
    var `enum` : EnumDeclSyntax? {
        var newMembers : MemberDeclBlockSyntax
        let leftBrace = SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)).withTrailingTrivia(.spaces(1))
        let rightBrace = SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.newlines(1))
        if let child = self.child {
            if child.identifier.text == self.parent.identifier.text {
                newMembers = child.members
            } else {
                newMembers = MemberDeclBlockSyntax {
                    $0.useLeftBrace(leftBrace)
                    let syntax = DeclSyntax(child)
                    let declList = SyntaxFactory.makeMemberDeclListItem(decl: syntax, semicolon: nil)
                    $0.addMember(declList)
                    $0.useRightBrace(rightBrace)
                }
            }
        } else {
            newMembers = MemberDeclBlockSyntax {
                $0.useLeftBrace(leftBrace)
                for member in self.members.flatMap({ $0.members }) {
                    $0.addMember(member)
                }
                $0.useRightBrace(rightBrace)
            }
        }
        return self.parent.withMembers(newMembers)
    }
    
}
