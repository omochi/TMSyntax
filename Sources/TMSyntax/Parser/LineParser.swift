import Foundation

internal final class LineParser {
    private static let backReferenceRegex: Regex = try! Regex(pattern: "\\\\(\\d+)")
    private static let invalidUnicode: Unicode.Scalar = Unicode.Scalar(0xFFFF)!
    private static let invalidString: String = String(String.UnicodeScalarView([invalidUnicode]))

    public init(line: String,
                matchStack: MatchStateStack)
    {
        self.line = line
        self.lineEndPosition = line.lineEndIndex
        self.position = line.startIndex
        self.matchStack = matchStack
        self.tokens = []
    }

    private let line: String
    private let lineEndPosition: String.Index
    private var position: String.Index
    private var matchStack: MatchStateStack
    private var tokens: [Token]
    
    private var lastState: MatchState {
        return matchStack.top!
    }
    private var currentScopes: [ScopeName] {
        return matchStack.items.compactMap { $0.scopeName }
    }

    public func parse() throws -> Parser.Result {
        while true {
            let matchPlans = collectMatchPlans()
            
            let positionInByte = line.utf8.distance(from: line.startIndex, to: position)
            
            trace("--- match plans \(matchPlans.count), position \(positionInByte) ---")
            for plan in matchPlans {
                trace("\(plan)")
            }
            trace("------")
            
            guard let result = try search(line: line,
                                          start: position,
                                          plans: matchPlans) else
            {
                trace("no match, end line")
                
                extendOuterScope(end: lineEndPosition)
                
                break
            }
            
            processMatchResult(result)
        }
        
        return Parser.Result(matchStack: matchStack, tokens: tokens)
    }
    
    private func collectMatchPlans() -> [MatchPlan] {
        var plans: [MatchPlan] = []
        
        let lastState = self.lastState

        switch lastState.rule.switcher {
        case .include,
             .match:
            break
        case .scope(let rule):
            switch rule.condition {
            case .beginEnd(let cond):
                let endPattern = lastState.endPattern!
                let endPlan = MatchPlan.endRule(rule, cond, endPattern)
                plans.append(endPlan)
            case .none:
                break
            }
            
            for e in rule.patterns {
                plans += e.collectEnterMatchPlans()
            }
        }
        
        return plans
    }
    
    private func search(line: String, start: String.Index, plans: [MatchPlan]) throws -> MatchResult? {
        var matchResults: [(Int, MatchResult)] = []
        
        for (index, plan) in plans.enumerated() {
            let regex = try plan.pattern.compile()
            if let match = regex.search(string: line, range: start..<lineEndPosition) {
                matchResults.append((index, MatchResult(plan: plan, match: match)))
            }
        }
        
        matchResults.sort { (a, b) -> Bool in
            let (ai, am) = a
            let (bi, bm) = b
            
            if am.match[].lowerBound != bm.match[].lowerBound {
                return am.match[].lowerBound < bm.match[].lowerBound
            }
            
            return ai < bi
        }
        
        guard let best = matchResults.first else {
            return nil
        }
        
        return best.1
    }
    
    private func processMatchResult(_ result: MatchResult) {
        trace("match!: \(result.plan)")
        
        let newPosition = result.match[].upperBound
        
        extendOuterScope(end: result.match[].lowerBound)
        
        switch result.plan {
        case .matchRule(let rule):
            let newState = MatchState(rule: rule,
                                      scopeName: rule.scopeName,
                                      endPattern: nil)
            matchStack.push(newState)
            buildCaptureTokens(result: result, captures: rule.captures)
            matchStack.pop()
        case .beginRule(let rule, let cond):
            let endPattern = resolveEndPatternBackReference(end: cond.end,
                                                            beginMatchResult: result.match)
            let newState = MatchState(rule: rule,
                                      scopeName: rule.scopeName,
                                      endPattern: endPattern)
            matchStack.push(newState)
            buildCaptureTokens(result: result, captures: cond.beginCaptures)    
        case .endRule(let rule, let cond, _):
            _ = rule
            buildCaptureTokens(result: result, captures: cond.endCaptures)
            matchStack.pop()
        }
        
        position = newPosition
    }
    
    private func resolveEndPatternBackReference(end: RegexPattern,
                                                beginMatchResult: Regex.Match) -> RegexPattern
    {
        var num = 0
        
        let newPattern = LineParser.backReferenceRegex.replace(string: end.value) { (match) in
            num += 1
            
            let captureIndex = Int(end.value[match[1]!])!
            
            guard let range = beginMatchResult[captureIndex] else {
                return LineParser.invalidString
            }
            return String(line[range])
        }

        if num == 0 {
            // return same object
            return end
        }
        
        return RegexPattern(newPattern, location: end.location)
    }
    
    private func buildCaptureTokens(result: MatchResult,
                                    captures: CaptureAttributes?) {
        let accum = ScopeAccumulator()
        
        var currentScopes = self.currentScopes
    
        let lastScope = currentScopes.last!
        currentScopes.removeLast()
        
        accum.items.append(ScopeAccumulator.Item(range: result.match[],
                                                 scope: lastScope))
        
        if let captures = captures {
            for (key, attr) in captures.dictionary {
                guard let captureIndex = Int(key),
                    let range = result.match[captureIndex] else
                {
                    continue
                }
                
                accum.items.append(ScopeAccumulator.Item(range: range,
                                                         scope: attr.name))
            }
        }
        
        let tokens = accum.buildTokens()
        for var token in tokens {
            token.scopes = currentScopes + token.scopes
            addToken(token)
        }
    }
    
    private func extendOuterScope(end: String.Index) {
        guard position < end else {
            return
        }
        
        let token = Token(range: position..<end,
                          scopes: currentScopes)
        addToken(token)
    }
    
    private func addToken(_ token: Token) {
        tokens.append(token)
    }
    
    private func trace(_ string: String) {
        print("[Parser trace] \(string)")
    }

}
