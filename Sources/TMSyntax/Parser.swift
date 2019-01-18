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
        self.ruleStack = RuleStack([grammer.rule])
    }
    
    public let lines: [String]
    public private(set) var currentLine: Int
    public var isAtEnd: Bool {
        return currentLine == lines.count
    }
    
    private let grammer: Grammer
    private var currentRule: Rule {
        return ruleStack.top!
    }
    private var ruleStack: RuleStack
    
    public func parseLine() throws {
        try _parseLine()
        currentLine += 1
    }
    
    private func _parseLine() throws {
        let line = lines[currentLine]
        
        var pos = line.startIndex
        while true {
            let matchPlans = currentRule.collectMatchPlans()
            
            guard let ret = try search(line: line, start: pos, plans: matchPlans) else {
                return
            }
            
            pos = ret.1[0].upperBound
        }
    }
    
    private func search(line: String, start: String.Index, plans: [MatchPlan]) throws -> (MatchPlan, Regex.Match)? {
        var matchResults: [(Int, MatchPlan, Regex.Match)] = []
        
        for (index, plan) in plans.enumerated() {
            let regex = try plan.compile()
            if let match = regex.search(string: line, range: start..<line.endIndex) {
                matchResults.append((index, plan, match))
            }
        }
        
        matchResults.sort { (a, b) -> Bool in
            let (ai, _, am) = a
            let (bi, _, bm) = b
            
            if am[0].lowerBound != bm[0].lowerBound {
                return am[0].lowerBound < bm[0].lowerBound
            }
            
            return ai < bi
        }
        
        guard let best = matchResults.first else {
            return nil
        }
        
        return (best.1, best.2)
    }
    
    private func processMatchRule(_ rule: MatchRule) {
        
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
