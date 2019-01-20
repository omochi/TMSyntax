import Foundation
import RichJSONParser

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
        lineLoop: while true {
            let matchPlans = collectMatchPlans(position: position)
            
            let positionInByte = line.utf8.distance(from: line.startIndex, to: position)
            
            trace("--- match plans \(matchPlans.count), position \(positionInByte) ---")
            for plan in matchPlans {
                trace("\(plan)")
            }
            trace("------")
            
            func _endPosition() -> String.Index {
                if let end = lastState.endPosition {
                    return end
                }
                return lineEndPosition
            }
            
            let endPosition = _endPosition()
            
            let searchRange = position..<endPosition
            guard let result = try search(line: line,
                                          range: searchRange,
                                          plans: matchPlans) else
            {
                trace("no match, end line")
    
                extendOuterScope(range: searchRange)
                
                var isPoped = false
                
                while true {
                    guard let stateEnd = lastState.endPosition,
                        stateEnd <= endPosition else
                    {
                        break
                    }
                    precondition(stateEnd == endPosition)
                    
                    trace("end position rule pop: \(lastState.rule)")
                    
                    matchStack.pop()
                    isPoped = true
                }
                
                position = endPosition
                
                if isPoped {
                    continue lineLoop
                }

                break lineLoop
            }
            
            processMatchResult(searchRange: searchRange,
                               result: result)
        }
        
        return Parser.Result(matchStack: matchStack, tokens: tokens)
    }
    
    private func collectMatchPlans(position: String.Index) -> [MatchPlan] {
        var plans: [MatchPlan] = []
        
        let lastState = self.lastState
        
        if let endPattern = lastState.endPattern {
            let endPlan = MatchPlan.createEnd(rule: lastState.rule as! ScopeRule,
                                              pattern: endPattern)
            plans.append(endPlan)
        }

        for e in lastState.patterns {
            plans += collectEnterMatchPlans(rule: e, position: position)
        }
        
        return plans
    }
    
    public func collectEnterMatchPlans(rule: Rule, position: String.Index) -> [MatchPlan] {
        switch rule.switcher {
        case .include(let rule):
            guard let target = rule.targetRule else {
                return []
            }
            return collectEnterMatchPlans(rule: target, position: position)
        case .match(let rule):
            return [MatchPlan.createMatch(rule: rule)]
        case .scope(let rule):
            if let _ = rule.begin {
                return [MatchPlan.createBegin(rule: rule)]
            } else if let ruleBeginPosition = rule.beginPosition {
                guard position <= ruleBeginPosition else {
                    return []
                }
                return [MatchPlan.createBeginPosition(rule: rule)]
            } else {
                var plans: [MatchPlan] = []
                for e in rule.patterns {
                    plans += collectEnterMatchPlans(rule: e, position: position)
                }
                return plans
            }
        }
    }
    
    private func search(line: String,
                        range: Range<String.Index>,
                        plans: [MatchPlan]) throws -> MatchResult?
    {
        typealias Record = (Int, MatchResult)
        
        var matchResults: [Record] = []
        
        for (index, plan) in plans.enumerated() {
            if let pattern = plan.pattern {
                let regex = try pattern.compile()
                if let match = regex.search(string: line, range: range) {
                    let result = Record(index,
                                        MatchResult(plan: plan,
                                                    match: match,
                                                    position: match[].lowerBound))
                    matchResults.append(result)
                }
            } else if let beginPosition = plan.beginPosition {
                let result = Record(index,
                                    MatchResult(plan: plan,
                                                match: nil,
                                                position: beginPosition))
                matchResults.append(result)
            }
        }
        
        func cmp(_ a: Record, _ b: Record) -> Bool {
            let (ai, am) = a
            let (bi, bm) = b
            
            if am.position != bm.position {
                return am.position < bm.position
            }
            
            return ai < bi
        }
        
        guard let best = matchResults.min(by: cmp) else {
            return nil
        }
        
        return best.1
    }
    
    private func processMatchResult(searchRange: Range<String.Index>,
                                    result: MatchResult)
    {
        trace("match!: \(result.plan)")
        
        extendOuterScope(range: searchRange.lowerBound..<result.position)
        
        switch result.plan {
        case .matchRule(let rule):
            let regexMatch = result.match!

            let newState = MatchState(rule: rule,
                                      patterns: [],
                                      scopeName: rule.scopeName,
                                      endPattern: nil,
                                      endPosition: regexMatch[].upperBound)
            pushState(newState)
            
            let captureRule = buildCaptureScopeRule(captures: rule.captures,
                                                    captureLocation: rule.pattern.location,
                                                    regexMatch: regexMatch)
            captureRule.parent = rule
            let captureState = MatchState.createSimpleScope(rule: captureRule)
            pushState(captureState)

            position = regexMatch[].lowerBound
            
        case .beginRule(let rule):
            let regexMatch = result.match!
            
            let ruleEndPattern = rule.end!
            let endPattern = resolveEndPatternBackReference(end: ruleEndPattern,
                                                            beginMatchResult: regexMatch)
            let newState = MatchState(rule: rule,
                                      patterns: rule.patterns,
                                      scopeName: rule.scopeName,
                                      endPattern: endPattern,
                                      endPosition: nil)
            pushState(newState)
            
            let captureRule = buildCaptureScopeRule(captures: rule.beginCaptures,
                                                    captureLocation: rule.begin?.location,
                                                    regexMatch: regexMatch)
            captureRule.parent = rule
            let captureState = MatchState.createSimpleScope(rule: captureRule)
            pushState(captureState)
            
            position = regexMatch[].lowerBound
        case .beginPositionRule(let rule):
            precondition(rule.beginPosition == result.position)
            let newState = MatchState(rule: rule,
                                      patterns: rule.patterns,
                                      scopeName: rule.scopeName,
                                      endPattern: rule.end,
                                      endPosition: rule.endPosition)
            pushState(newState)
            position = rule.beginPosition!
        case .endRule(let rule, _):
            let regexMatch = result.match!
            matchStack.pop()
            
            let endScopeRule = ScopeRule.createRangeRule(sourceLocation: rule.sourceLocation,
                                                         range: regexMatch[],
                                                         patterns: [],
                                                         scopeName: rule.scopeName)
            endScopeRule.parent = rule.parent
            let newState = MatchState.createSimpleScope(rule: endScopeRule)
            pushState(newState)
            
            let captureRule = buildCaptureScopeRule(captures: rule.endCaptures,
                                                    captureLocation: rule.end?.location,
                                                    regexMatch: regexMatch)
            captureRule.parent = rule
            let captureState = MatchState.createSimpleScope(rule: captureRule)
            pushState(captureState)
            
            position = regexMatch[].lowerBound
        }
    }
    
    private func buildCaptureScopeRule(captures: CaptureAttributes?,
                                       captureLocation: SourceLocation?,
                                       regexMatch: Regex.Match) -> ScopeRule {
        var capturePatterns: [Rule] = []
        
        if let captures = captures {
            for (key, attr) in captures.dictionary {
                guard let captureIndex = Int(key),
                    captureIndex != 0,
                    let range = regexMatch[captureIndex] else
                {
                    continue
                }
                
                let captureRule = ScopeRule.createRangeRule(sourceLocation: attr.sourceLocation,
                                                            range: range,
                                                            patterns: attr.patterns,
                                                            scopeName: attr.name)
                captureRule.name = "capture(\(captureIndex))"
                capturePatterns.append(captureRule)
            }
        }
        
        let capture0Name = captures?.dictionary["0"]?.name
        
        // TODO: loc
        let capture0Rule = ScopeRule.createRangeRule(sourceLocation: captureLocation,
                                                     range: regexMatch[],
                                                     patterns: capturePatterns,
                                                     scopeName: capture0Name)
        capture0Rule.name = "capture(0)"
        
        return capture0Rule
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
    
    private func extendOuterScope(range: Range<String.Index>) {
        guard !range.isEmpty else {
            return
        }
        
        let token = Token(range: range,
                          scopes: currentScopes)
        addToken(token)
    }
    
    private func pushState(_ state: MatchState) {
        var state = state
        
        if let currentEndPosition = lastState.endPosition {
            if let newEndPosition = state.endPosition {
                precondition(newEndPosition <= currentEndPosition)
            } else {
                state.endPosition = currentEndPosition
            }
        }
        
        matchStack.push(state)
    }
    
    private func addToken(_ token: Token) {
        tokens.append(token)
    }
    
    private func trace(_ string: String) {
        print("[Parser trace] \(string)")
    }

}
