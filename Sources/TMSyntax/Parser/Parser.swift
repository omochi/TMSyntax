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
                            grammar: Grammar)
    {
        self.init(lines: string.splitLines(),
                  grammar: grammar)
    }
    
    public init(lines: [String],
                grammar: Grammar)
    {
        self.lines = lines
        self.currentLineIndex = 0
        self.grammar = grammar
        self.stateStack = ParserStateStack([])
        
        makeLine()
        
        let rule = grammar.rule
        
        stateStack.stack.append(ParserState(rule: rule,
                                            phase: .scopeContent,
                                            patterns: rule.patterns,
                                            captureAnchors: [],
                                            scopePath: ScopePath([grammar.scopeName]),
                                            beginMatchResult: nil,
                                            beginLineIndex: nil,
                                            endPattern: nil,
                                            endPosition: nil))
    }
    
    public let lines: [String]
    public private(set) var currentLineIndex: Int
    public private(set) var currentLine: String?
    public var isAtEnd: Bool {
        return currentLineIndex == lines.count
    }
    
    public var isTraceEnabled: Bool = false
    
    private let grammar: Grammar
    private var stateStack: ParserStateStack
    
    private func makeLine() {
        guard currentLineIndex < lines.count else {
            currentLine = nil
            return
        }
        
        var line = lines[currentLineIndex]
        line = String(line[..<line.lineEndIndex]) + "\n"
        self.currentLine = line
    }
    
    public func parseLine() throws -> [Token] {
        let parser = LineParser(line: currentLine!,
                                lineIndex: currentLineIndex,
                                stateStack: stateStack,
                                grammar: grammar,
                                isTraceEnabled: isTraceEnabled)
        let result = try parser.parse()
        self.stateStack = result.stateStack
        currentLineIndex += 1
        makeLine()
        return result.tokens
    }
    
}
