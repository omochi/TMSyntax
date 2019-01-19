import Foundation

internal extension Unicode.Scalar {
    static let cr = Unicode.Scalar(UInt8(0x0D))
    static let lf = Unicode.Scalar(UInt8(0x0A))
}

public final class Parser {
    public struct Result {
        public var matchStack: MatchStateStack
        public var tokens: [Token]
        
        public init(matchStack: MatchStateStack,
                    tokens: [Token])
        {
            self.matchStack = matchStack
            self.tokens = tokens
        }
    }
    
    public convenience init(string: String,
                            grammer: Grammer)
    {
        self.init(lines: string.splitLines(),
                  grammer: grammer)
    }
    
    public init(lines: [String],
                grammer: Grammer)
    {
        self.lines = lines
        self.currentLineIndex = 0
        self.grammer = grammer
        self.matchStack = MatchStateStack()
        
        matchStack.push(MatchState(rule: grammer.rule,
                                   scopeName: grammer.rule.scopeName,
                                   endPattern: nil))
    }
    
    public let lines: [String]
    public private(set) var currentLineIndex: Int
    public var currentLine: String? {
        guard currentLineIndex < lines.count else {
            return nil
        }
        return lines[currentLineIndex]
    }
    public var isAtEnd: Bool {
        return currentLineIndex == lines.count
    }
    
    private let grammer: Grammer
    private var matchStack: MatchStateStack
    
    public func parseLine() throws -> [Token] {
        let parser = LineParser(line: currentLine!,
                                matchStack: matchStack)
        let result = try parser.parse()
        self.matchStack = result.matchStack
        currentLineIndex += 1
        return result.tokens
    }
    
}
