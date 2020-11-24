//
//  String.swift
//  LocalizableDSL
//
//  Created by Ruslan Alikhamov on 17.09.2020.
//

import Foundation
import SwiftSyntax

extension String {
    
    func formatIdentifier(_ string: String, capitalization: (String) -> String) -> TokenSyntax {
        let characterSet = CharacterSet.alphanumerics.inverted
        let separated = (string as NSString).components(separatedBy: characterSet)
        let output = separated.joined(separator: "")
        let tokenKind = TokenKind(rawValue: output.lowercased())
        if tokenKind.isKeyword {
            return SyntaxFactory.makeIdentifier("`\(capitalization(output))`")
        } else if output == "type" {
            // workaround for: https://bugs.swift.org/browse/SR-1072
            return SyntaxFactory.makeIdentifier("L_\(capitalization(output))")
        } else {
            let identifier = SyntaxFactory.makeIdentifier(capitalization(output))
            if case .identifier(let text) = identifier.tokenKind, !text.isEmpty {
                return identifier
            }
        }
        return SyntaxFactory.makeIdentifier(capitalization("InvalidSymbolFound"))
    }
    
    var safeVarIdentifier : TokenSyntax {
        self.formatIdentifier(self, capitalization: \Self.decapitalizedFirst)
    }

    var safeEnumIdentifier : TokenSyntax {
        self.formatIdentifier(self, capitalization: \Self.capitalizedFirst)
    }
    
    private mutating func modifyFirst(shouldCapitalize: Bool) {
        let function = shouldCapitalize ? Character.uppercased : Character.lowercased
        if let character = self.first {
            let modified = function(character)()
            let startIndex = self.startIndex
            let range = startIndex ..< self.index(after: startIndex)
            self.replaceSubrange(range, with: String(modified))
        }
    }
    
    var capitalizedFirst : String {
        var retVal = self
        retVal.modifyFirst(shouldCapitalize: true)
        return retVal
    }
    
    var decapitalizedFirst : String {
        var retVal = self
        retVal.modifyFirst(shouldCapitalize: false)
        return retVal
    }
    
}

extension String {
    
    func prefixComparisonScore(string: String) -> Int {
        return self.commonPrefix(with: string).count
    }
    
}
