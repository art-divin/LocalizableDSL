//
//  DSL.swift
//  LocalizableDSL
//
//  Created by Ruslan Alikhamov on 22.08.2020.
//

import Foundation
import SwiftSyntax

extension EnumDeclSyntax {
    
    static func +(lhs: EnumDeclSyntax, rhs: EnumDeclSyntax) -> EnumDeclSyntax? {
        if lhs.identifier.text == rhs.identifier.text {
            let lhsMembers = lhs.members
            let rhsMembers = rhs.members
            
            var tree = EnumTree(parent: lhs)
            tree.members.append(lhsMembers)
            tree.members.append(rhsMembers)
            
            let newEnum = tree.enum
            return newEnum
        }
        return nil
    }
    
}

public class DSL {
    
    public init() {}
    
    public func parse(input: String) throws -> String {
        var rows = input.split(separator: "\n").map { String($0) }.filter { !$0.isEmpty && ($0.hasPrefix("/*") && $0.hasSuffix("*/")) || ($0.hasPrefix("\"") && $0.contains("=")) }

        rows = rows.map {
            var retVal = $0
            if !$0.hasPrefix("/*") {
                retVal.insert(contentsOf: DSLVisitor.Declaration.genericEnum, at: $0.index(after: $0.startIndex))
            }
            return retVal
        }
        
        let reduced = rows.reduce(into: String()) {
            // detect if comment
            // if comment - don't insert \n after it, combine the next line with it
            // insert \n otherwise
            if $1.hasPrefix("/*") {
                $0.append($1)
            } else {
                $0.append($1 + "\n")
            }
        }
        
        rows = reduced.split(separator: "\n").map { String($0) }
        
        var visitors : [DSLVisitor] = []
        
        
        
        try rows.forEach {
            let visitor : DSLVisitor = .init()
            let parsed = try SyntaxParser.parse(source: $0)
            visitor.walk(parsed)
            visitors.append(visitor)
        }

        let checked = self.reduce(visitors: visitors)
        var retVal = String()
        retVal += checked.flatMap { $0.declaration.reducedString }
        return retVal
    }
    
    func reduce(visitors: [DSLVisitor]) -> [DSLVisitor] {
        var output : [DSLVisitor] = []
        var visitorsCopy = visitors.sortedByPrefixes()
        while true {
            let current = visitorsCopy.removeFirst()
            if current.count == 2,
                let first = current.first,
                let next = current.last
            {
                if let newList = first.declaration.list + next.declaration.list {
                    first.declaration.list = newList
                    output.append(first)
                } else {
                    output.append(first)
                    output.append(next)
                }
            } else if let first = current.first {
                output.append(first)
            }
            if visitorsCopy.isEmpty {
                if output.count < 2 {
                    break
                }
                visitorsCopy = output.sortedByPrefixes()
                output.removeAll()
            }
        }
        return output
    }
    
}
