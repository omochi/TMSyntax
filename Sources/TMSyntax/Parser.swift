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
    
    public func parseLine() {

        
        process(rule: currentRule)
    }
    
    private func process(rule: Rule) {
        switch rule.switcher {
        case .include(let rule):
            if let target = rule.target {
                process(rule: target)
            }
        case .match(let rule):
            break
        case .scope(let rule):
            //
            for e in rule.patterns {
                process(rule: e)
            }
        }
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
