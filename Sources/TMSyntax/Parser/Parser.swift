import Foundation

internal extension Unicode.Scalar {
    static let cr = Unicode.Scalar(UInt8(0x0D))
    static let lf = Unicode.Scalar(UInt8(0x0A))
}

public final class Parser {
    public struct Result {
        public var stateStack: ParserStateStack
        public var tokens: [Token]
        
        public init(stateStack: ParserStateStack,
                    tokens: [Token])
        {
            self.stateStack = stateStack
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
        self.stateStack = ParserStateStack([])
        
        stateStack.stack.append(ParserState(phase: .content(grammer.rule),
                                            patterns: grammer.rule.patterns,
                                            captureAnchors: [],
                                            scopePath: [grammer.scopeName],
                                            endPattern: nil,
                                            endPosition: nil))
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
    
    public var isTraceEnabled: Bool = false
    
    private let grammer: Grammer
    private var stateStack: ParserStateStack
    
    public func parseLine() throws -> [Token] {
        let parser = LineParser(line: currentLine!,
                                stateStack: stateStack,
                                grammer: grammer,
                                isTraceEnabled: isTraceEnabled)
        let result = try parser.parse()
        self.stateStack = result.stateStack
        currentLineIndex += 1
        return result.tokens
    }
    
}
