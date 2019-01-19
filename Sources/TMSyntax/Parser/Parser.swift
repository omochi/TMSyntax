import Foundation

internal extension Unicode.Scalar {
    static let cr = Unicode.Scalar(UInt8(0x0D))
    static let lf = Unicode.Scalar(UInt8(0x0A))
}

public final class Parser {
    public init(string: String,
                grammer: Grammer) {
        self.lines = Parser.splitLines(string)
        self.currentLine = 0
        self.grammer = grammer
        self.ruleStack = MatchStateStack()
        
        ruleStack.push(MatchState(rule: grammer.rule,
                                  scopeName: grammer.rule.scopeName))
    }
    
    public let lines: [String]
    public private(set) var currentLine: Int
    public var isAtEnd: Bool {
        return currentLine == lines.count
    }
    
    private let grammer: Grammer
    private var currentRule: Rule {
        return ruleStack.top!.rule
    }
    private var currentScopes: [ScopeName] {
        return ruleStack.items.compactMap { $0.scopeName }
    }
    private var ruleStack: MatchStateStack
//    private var tokenSplitter: TokenSplitter!
    private var tokens: [Token]!
    private var line: String!
    private var position: String.Index!
    
    public func parseLine() throws -> [Token] {
        line = lines[currentLine]
        position = line.startIndex
        tokens = []
//        tokenSplitter = TokenSplitter()

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
                
                extendOuterScope(end: line.endIndex)
                
                currentLine += 1
                return tokens
//                return tokenSplitter.tokens
            }
            
            processMatchResult(result)
        }
    }
    
    private func collectMatchPlans() -> [MatchPlan] {
        var plans: [MatchPlan] = []
        
        switch currentRule.switcher {
        case .include,
             .match:
            break
        case .scope(let rule):
            switch rule.condition {
            case .beginEnd(let cond):
                let endPlan = MatchPlan.endRule(rule, cond)
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
            let regex = try plan.regexPattern.compile()
            if let match = regex.search(string: line, range: start..<line.endIndex) {
                matchResults.append((index, MatchResult(plan: plan, match: match)))
            }
        }
        
        matchResults.sort { (a, b) -> Bool in
            let (ai, am) = a
            let (bi, bm) = b
            
            if am.match[0].lowerBound != bm.match[0].lowerBound {
                return am.match[0].lowerBound < bm.match[0].lowerBound
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
        
        let newPosition = result.match[0].upperBound
        
        extendOuterScope(end: result.match[0].lowerBound)
        
        switch result.plan {
        case .matchRule(let rule):
            
            let token = Token(range: result.match[0],
                              scopes: currentScopes + [rule.scopeName])
            addToken(token)
            
            
//            tokenSplitter.add(range: result.match[0], scopeName: rule.scopeName)
        case .beginRule(let rule, let cond):
            let newState = MatchState(rule: rule, scopeName: rule.scopeName)
            ruleStack.push(newState)
            
            var start = result.match[0].lowerBound
            
            let token = Token(range: result.match[0], scopes: currentScopes)
            addToken(token)
            
            

        case .endRule(let rule, let cond):
            let token = Token(range: result.match[0], scopes: currentScopes)
            addToken(token)
            
            ruleStack.pop()
        }
        
        position = newPosition
    }
    
    private func extendOuterScope(end: String.Index) {
        guard position < end else {
            return
        }
        
        let token = Token(range: position..<end,
                          scopes: currentScopes)
        addToken(token)
        
//        if let scope = currentRule.scopeName {
//            
//            
//            tokenSplitter.add(range: position..<end, scopeName: scope)
//        }
    }
    
    private func addToken(_ token: Token) {
        tokens.append(token)
    }
    
    public static func splitLines(_ string: String) -> [String] {
        var result = [String]()
        
        let string = string.unicodeScalars
        
        var pos = string.startIndex
        var lineStart = pos
        while true {
            if pos == string.endIndex {
                if lineStart != pos {
                    result.append(String(string[lineStart..<pos]))
                    lineStart = pos
                }
                break
            }
            
            let c0 = string[pos]
            
            if c0 == .cr {
                pos = string.index(after: pos)
                if pos == string.endIndex {
                    result.append(String(string[lineStart..<pos]))
                    lineStart = pos
                    break
                }
                
                let c1 = string[pos]
                if c1 == .lf {
                    pos = string.index(after: pos)
                    result.append(String(string[lineStart..<pos]))
                    lineStart = pos
                } else {
                    result.append(String(string[lineStart..<pos]))
                    lineStart = pos
                }
            } else if c0 == .lf {
                pos = string.index(after: pos)
                result.append(String(string[lineStart..<pos]))
                lineStart = pos
            } else {
                pos = string.index(after: pos)
            }
        }
        
        return result
    }
    
    private func trace(_ string: String) {
        print("[Parser trace] \(string)")
    }
}
