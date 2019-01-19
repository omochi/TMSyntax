import Foundation

internal extension Unicode.Scalar {
    static let cr = Unicode.Scalar(UInt8(0x0D))
    static let lf = Unicode.Scalar(UInt8(0x0A))
}

public final class Parser {
    public convenience init(string: String,
                            grammer: Grammer)
    {
        self.init(lines: Parser.splitLines(string),
                  grammer: grammer)
    }
    
    public init(lines: [String],
                grammer: Grammer)
    {
        self.lines = lines
        self.currentLine = 0
        self.grammer = grammer
        self.matchStack = MatchStateStack()
        
        matchStack.push(MatchState(rule: grammer.rule,
                                  scopeName: grammer.rule.scopeName))
    }
    
    public let lines: [String]
    public private(set) var currentLine: Int
    public var isAtEnd: Bool {
        return currentLine == lines.count
    }
    
    private let grammer: Grammer
    private var matchStack: MatchStateStack
    
    public func parseLine() throws -> [Token] {
        let line = lines[currentLine]
        let parser = LineParser(matchStack: matchStack, line: line)
        let tokens = try parser.parse()
        currentLine += 1
        return tokens
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
