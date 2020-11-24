//
//  DSLLinkedList.swift
//  LocalizableDSL
//
//  Created by Ruslan Alikhamov on 17.09.2020.
//

import Foundation
import SwiftSyntax

class DSLLinkedList {
    
    weak var next : DSLLinkedList?
    var previous : DSLLinkedList?
    
    var `class` : ClassDeclSyntax?
    
    var `enum` : EnumDeclSyntax?
    var value : String?
    
    var _comment : String?
    var comment: String? {
        get {
            let characters = CharacterSet.alphanumerics.inverted
            return self._comment?.trimmingCharacters(in: characters)
        }
        set {
            self._comment = newValue
        }
    }
    
    var token : TokenKind?
    
    var top : DSLLinkedList {
        var retVal = self
        while retVal.previous != nil {
            retVal = retVal.previous!
        }
        return retVal
    }
    
    func droppedLast() -> DSLLinkedList {
        guard let previous = self.previous else {
            fatalError("miscondifured linked list")
        }
        return previous
    }
    
    var member : MemberDeclListItemSyntax? {
        var member : DeclSyntax? = nil
        let closingBracket = SyntaxFactory.makeRightBraceToken(leadingTrivia: .newlines(1), trailingTrivia: .tabs(1))
        if self.next == nil, let staticVar = self.staticVar {
            member = DeclSyntax(staticVar)
            self.previous?.enum = nil
        } else if var `enum` = self.enum {
            if let member = self.next?.member {
                // self.enum becomes nil after self.staticVar is used to avoid redundant enum
                if self.enum == nil {
                    return member
                }
                let openingBracket = SyntaxFactory.makeLeftBraceToken(leadingTrivia: .spaces(1))
                let members = MemberDeclBlockSyntax {
                    $0.useLeftBrace(openingBracket)
                    $0.addMember(member)
                    $0.useRightBrace(closingBracket)
                }
                `enum` = `enum`.withMembers(members)
                self.enum = `enum`
            }
            member = DeclSyntax(`enum`)
        } else {
            return nil
        }
        return SyntaxFactory.makeMemberDeclListItem(decl: member!, semicolon: nil)
    }
    
    var _reduced : MemberDeclBlockSyntax?
    var reduced : MemberDeclBlockSyntax? {
        if self._reduced != nil {
            return self._reduced
        }
        let list : DSLLinkedList = self.top
        let members = MemberDeclBlockSyntax {
            if let member = list.member {
                $0.addMember(member)
            }
        }
        return members
    }
    
    // converts `enum keyword` into `static let keyword = "value"`
    var staticVar : VariableDeclSyntax? {
        guard let value = self.value, self.`enum` == nil, let `enum` = self.previous?.`enum` else {
            return nil
        }
        let staticValue = SyntaxFactory.makeStaticKeyword().withLeadingTrivia(.newlines(1) + .spaces(1))
        let varValue = SyntaxFactory.makeLetKeyword().withLeadingTrivia(.spaces(1))
        let identifier = `enum`.identifier.text.safeVarIdentifier.withLeadingTrivia(.spaces(1))
        let equals = SyntaxFactory.makeEqualToken(leadingTrivia: .spaces(1), trailingTrivia: .spaces(1))
        let stringLiteral = SyntaxFactory.makeStringLiteral("NSLocalizedString(\"\(value)\", comment: \"\(self.comment ?? "")\")")
        let varDecl = VariableDeclSyntax {
            $0.addAttribute(Syntax(staticValue))
            $0.addAttribute(Syntax(varValue))
            $0.addAttribute(Syntax(identifier))
            $0.addAttribute(Syntax(equals))
            $0.addAttribute(Syntax(stringLiteral))
        }
        return varDecl
    }
    
    struct SmallEnumTree : CustomDebugStringConvertible {
        
        internal init(generated: EnumDeclSyntax? = nil, rhs: DSLLinkedList? = nil, lhs: DSLLinkedList? = nil) {
            self.generated = generated
            self.rhs = rhs
            self.lhs = lhs
            self.lhs?.enum = generated
        }
        
        var generated : EnumDeclSyntax?
        var rhs : DSLLinkedList?
        var lhs : DSLLinkedList?
        
        mutating func update(new: EnumDeclSyntax?) {
            if self.lhs?.top.enum?.identifier.text != new?.identifier.text {
                self.lhs?.enum = new
            }
            self.generated = new
        }
        
        var debugDescription: String {
            var retVal = ""
            retVal += self.lhs.debugDescription
            retVal += self.rhs.debugDescription
            return retVal
        }
        
    }
    
    static func +(lhs: DSLLinkedList, rhs: DSLLinkedList) -> DSLLinkedList? {
        _ = lhs.reduced
        _ = rhs.reduced
        
        var lhsNext : DSLLinkedList? = lhs.top
        var rhsNext : DSLLinkedList? = rhs.top
        
        var combined : [SmallEnumTree] = []
        
        while true {
            if let lhsEnum = lhsNext?.enum,
                let rhsEnum = rhsNext?.enum,
                let newEnum = lhsEnum + rhsEnum
            {
                let tree = SmallEnumTree(generated: newEnum, rhs: rhsNext, lhs: lhsNext)
                combined.append(tree)
            } else {
                break
            }
            
            lhsNext = lhsNext?.next
            rhsNext = rhsNext?.next
            
            guard lhsNext != nil, rhsNext != nil else {
                break
            }
        }
        
        
        if combined.isEmpty {
            return nil
        }
        
        var topLast : EnumDeclSyntax?
        var last = combined.popLast()
        while last != nil {
            if !combined.isEmpty {
                guard var current = combined.popLast(), let currentEnum = current.generated else {
                    break
                }
                var tree = EnumTree(parent: currentEnum)
                tree.child = last?.generated
                
                topLast = tree.enum

                current.update(new: topLast)
                last = current
            } else {
                break
            }
        }
        
        if topLast == nil {
            topLast = last?.generated
        }
        lhs.top.enum = topLast
        
        let decl = DeclSyntax(topLast!)
        let mem = SyntaxFactory.makeMemberDeclListItem(decl: decl, semicolon: nil)
        
        let reduced = MemberDeclBlockSyntax {
            $0.addMember(mem)
        }
        lhs._reduced = reduced
        return lhs
        
    }
    
}

extension DSLLinkedList : CustomDebugStringConvertible {
    
    var debugDescription : String {
        var retVal = "DSLLinkedList: \(self.value ?? "undefined")"
        retVal += self.enum?.debugDescription ?? "" + "\n"
        var next = self.top.next
        while next != nil {
            retVal += next.debugDescription + "\n"
            next = next?.next
        }
        return retVal
    }
    
}
