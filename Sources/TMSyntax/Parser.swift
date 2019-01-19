import Foundation

internal extension Unicode.Scalar {
    static let cr = Unicode.Scalar(UInt8(0x0D))
    static let lf = Unicode.Scalar(UInt8(0x0A))
}

public class Parser {
    public init(string: String,
                grammer: Grammer) {
        self.lines = Parser.splitLines(string)
        self.currentLine = 0
        self.grammer = grammer
        self.ruleStack = MatchRuleStack()
        
        ruleStack.push(MatchRuleStack.Item(rule: grammer.rule,
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
    private var ruleStack: MatchRuleStack
    
    private var tokens: [Token] = []
    
    public func parseLine() throws -> [Token] {
        tokens = []
        
        try _parseLine()
        currentLine += 1
        return tokens
    }
    
    private func _parseLine() throws {
        let line = lines[currentLine]
        
        var pos = line.startIndex
        while true {
            let matchPlans = currentRule.collectMatchPlans()
            
            guard let result = try search(line: line, start: pos, plans: matchPlans) else {
                return
            }
            
            processMatchResult(result)
            
            pos = result.match[0].upperBound
        }
    }
    
    private func search(line: String, start: String.Index, plans: [MatchPlan]) throws -> MatchResult? {
        var matchResults: [(Int, MatchResult)] = []
        
        for (index, plan) in plans.enumerated() {
            let regex = try plan.compile()
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
        switch result.plan {
        case .matchRule(let rule):
            buildToken(range: result.match[0], scopeName: rule.scopeName)
        case .beginRule(let rule, let cond):
            // TODO
            break
        }
    }
    
    private func buildToken(range: Range<String.Index>, scopeName: ScopeName?) {
        var scopes: [ScopeName] = []
        
        for item in ruleStack.items {
            if let scope = item.scopeName {
                scopes.append(scope)
            }
        }
        if let scope = scopeName {
            scopes.append(scope)
        }
        
        let token = Token(range: range, scopes: scopes)
        self.tokens.append(token)
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
}
