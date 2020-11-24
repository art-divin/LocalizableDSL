//
//  Array.swift
//  LocalizableDSL
//
//  Created by Ruslan Alikhamov on 17.09.2020.
//

import Foundation

extension Array where Element == DSLVisitor {
    
    class Score : CustomDebugStringConvertible {
        var value : DSLVisitor
        var bestMatch : DSLVisitor?
        var score : Int?
        
        init(value: DSLVisitor) {
            self.value = value
        }
        
        func attempt(match: DSLVisitor) -> Bool {
            guard let selfValue = self.value.declaration.list.value,
                let matchValue = match.declaration.list.value else
            {
                return false
            }
            let score = selfValue.prefixComparisonScore(string: matchValue)

            if self.score == nil || self.score ?? 0 < score {
                
                if let existingScore = self.value.score,
                    existingScore.score ?? 0 >= score {
                    return false
                }
                
                self.score = score
                
                match.score?.bestMatch = nil
                self.bestMatch = match
                self.bestMatch?.score = self
                
                self.value.score?.bestMatch = nil
                self.value.score = self
                
                return true
            }
            return false
        }
        
        var array : [DSLVisitor] {
            var retVal : [DSLVisitor?] = []
            retVal.append(self.value)
            retVal.append(self.bestMatch)
            return retVal.compactMap { $0 }
        }
        
        var debugDescription: String {
            "\(self.value.declaration.list.value ?? "undefined") with \(self.bestMatch?.declaration.list.value ?? "undefined")"
        }
        
    }
    
    func sortedByPrefixes() -> [[DSLVisitor]] {
        guard self.count > 1 else {
            return [self]
        }
        self.forEach { $0.score = nil }
        let sorted = self.sorted()
        var output : [Score] = []
        for idx in 0 ..< sorted.count {
            let value = sorted[idx]
            let score = Score(value: value)
            var swapped = false
            var entered = false
            for innerIdx in idx + 1 ..< sorted.count {
                entered = true
                let innerValue = sorted[innerIdx]
                if score.attempt(match: innerValue) {
                    swapped = true
                }
            }
            if swapped || (!entered && value.score?.bestMatch == nil) {
                output.append(score)
            }
        }
        
        return output.map { $0.array }
    }
    
}
