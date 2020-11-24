//
//  DSLVisitor.swift
//  LocalizableDSL
//
//  Created by Ruslan Alikhamov on 17.09.2020.
//

import Foundation

import SwiftSyntax
import SwiftFormat
import SwiftFormatConfiguration

class DSLVisitor : SyntaxVisitor {
    
    struct Declaration {
        
        static let genericEnum = "L."
        
        var items : [DSLLinkedList] = []
        
        var list = DSLLinkedList()
        
        var processor : DSLVisitor = .init()
        var value : String?
        var comment : String?
        private lazy var numberFormatter : NumberFormatter = {
            let retVal = NumberFormatter()
            return retVal
        }()

        private mutating func createNode(identifier: String) {
            let enumValue = self.enumPlaceholder(with: identifier)
            self.list.enum = enumValue
            self.list.value = identifier
            
            let newList = DSLLinkedList()
            newList.previous = self.list
            self.list.next = newList
            self.items.append(newList)
            self.list = newList
        }
        
        mutating func process(node: TokenSyntax) throws {
            if node.nextToken != nil {
                switch node.tokenKind {
                    case .integerLiteral(var text):
                        let defaultString = "InvalidSymbolFound" + text
                        if let numberString = self.numberFormatter.number(from: text) {
                            let spelled = NumberFormatter.localizedString(from: numberString, number: .spellOut)
                            text = spelled
                        } else {
                            text = defaultString
                        }
                        self.createNode(identifier: text)
                    case .stringLiteral(let text): fallthrough
                    case .stringSegment(let text):
                        if self.list.token == .some(.equal) {
                            if let value = self.list.value, value.hasPrefix(Self.genericEnum) {
                                self.list.value = value.replacingOccurrences(of: Self.genericEnum, with: "")
                            }
                            return
                        }
                        
                        let syntax = try SyntaxParser.parse(source: text)
                        self.processor.walk(syntax)
                        
                        let innerList = self.processor.declaration.list
                        self.items.append(contentsOf: self.processor.declaration.items)
                        self.list.previous = innerList
                        innerList.next = self.list
                        self.value = innerList.value
                        self.list.value = text
                        self.list.comment = self.comment
                    case .identifier:
                        self.createNode(identifier: node.text)
                    case .equal:
                        self.list.token = node.tokenKind
                        let list = self.list
                        list.previous = self.list.previous?.droppedLast()
                        list.previous?.next = list
                        list.comment = self.comment
                        self.list = list
                    default:
                        if node.leadingTrivia.numberOfComments >= 1 {
                            switch node.leadingTrivia[0] {
                                case .blockComment(let string):
                                    self.list.comment = string
                                    self.comment = string
                                default: return
                            }
                        } else {
                            self.value = node.text
                        }
                }
            } else {
                // no-op, the end
            }
        }
        
        // output: enum
        func enumPlaceholder(with text: String) -> EnumDeclSyntax {
            let keyword = text.safeEnumIdentifier
            let enumKeyword = SyntaxFactory.makeEnumKeyword(trailingTrivia: .spaces(1))
            let openingBracket = SyntaxFactory.makeLeftBraceToken(leadingTrivia: .spaces(1))
            let enumValue = EnumDeclSyntax {
                $0.useEnumKeyword(enumKeyword)
                $0.useIdentifier(keyword)
                $0.useMembers(MemberDeclBlockSyntax {
                    $0.useLeftBrace(openingBracket)
                })
            }
            return enumValue
        }
        
        var reduced : MemberDeclBlockSyntax? {
            self.list.reduced
        }
        
        var reducedString : String {
            let token = TokenSyntax(Syntax(SyntaxFactory.makeToken(.rightBrace, presence: .present)))
            let item = SyntaxFactory.makeCodeBlockItem(item: Syntax(self.reduced)!, semicolon: nil, errorTokens: nil)
            let list = SyntaxFactory.makeCodeBlockItemList([item])
            var source = SyntaxFactory.makeSourceFile(statements: list, eofToken: token!)
            source = source.withEOFToken(nil)
            var file = String()
            source.write(to: &file)
            
            let tempURL = NSTemporaryDirectory()
            // TODO: use application temp folder
            let url = URL(fileURLWithPath: tempURL + "temperson.tmp")
            try! file.write(to: url, atomically: true, encoding: .utf8)
            
            let formatter = SwiftFormatter(configuration: Configuration())
            var output = String()
            do {
                try formatter.format(contentsOf: url, to: &output)
            } catch {
                print(error)
            }
            return output
        }
        
    }
    
    var score : Array<DSLVisitor>.Score?
    
    lazy var declaration : Declaration = {
        return .init()
    }()

    override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
        try? self.declaration.process(node: node)
        if self.declaration.list.token == .some(.equal) {
            return .skipChildren
        }
        
        return .visitChildren
    }
    
}

extension DSLVisitor : Comparable {
    
    static func < (lhs: DSLVisitor, rhs: DSLVisitor) -> Bool {
        lhs.declaration.list.value ?? "" < rhs.declaration.list.value ?? ""
    }
    
    static func == (lhs: DSLVisitor, rhs: DSLVisitor) -> Bool {
        lhs.declaration.list.value == rhs.declaration.list.value
    }
    
}
