import Foundation

public struct ParserState {
    public enum Phase {
        case rootContent
        case match(Match)
        case beginEndBegin(BeginEndBegin)
        case beginEndContent(BeginEndBegin)
        case beginEndEnd(BeginEndBegin, BeginEndEnd)
        case beginWhileBegin(BeginWhileState)
        case captureAnchor
    }
    
    public struct Match {
        public var matchResult: Regex.MatchResult
        
        public init(matchResult: Regex.MatchResult) {
            self.matchResult = matchResult
        }
    }
    
    public struct BeginEndBegin {
        public var matchResult: Regex.MatchResult
        public var lineIndex: Int
        public var endPattern: RegexPattern
        public var contentName: ScopeName?
        
        public init(matchResult: Regex.MatchResult,
                    lineIndex: Int,
                    endPattern: RegexPattern,
                    contentName: ScopeName?)
        {
            self.matchResult = matchResult
            self.lineIndex = lineIndex
            self.endPattern = endPattern
            self.contentName = contentName
        }
    }
    
    public struct BeginEndEnd {
        public var matchResult: Regex.MatchResult
        
        public init(matchResult: Regex.MatchResult) {
            self.matchResult = matchResult
        }
    }
    
    public struct BeginWhileState {
        public var matchResult: Regex.MatchResult
        public var lineIndex: Int
        public var whilePattern: RegexPattern
        public var contentName: ScopeName?
        
        public init(matchResult: Regex.MatchResult,
                    lineIndex: Int,
                    whilePattern: RegexPattern,
                    contentName: ScopeName?)
        {
            self.matchResult = matchResult
            self.lineIndex = lineIndex
            self.whilePattern = whilePattern
            self.contentName = contentName
        }
    }
    
    public struct WhileCondition {
        public var rule: BeginWhileRule
        public var condition: RegexPattern
        
        public init(rule: BeginWhileRule,
                    condition: RegexPattern)
        {
            self.rule = rule
            self.condition = condition
        }
    }
    
    public var rule: Rule?
    public var phase: Phase
    public var patterns: [Rule]
    public var captureAnchors: [CaptureAnchor]
    public var scopePath: ScopePath
    public var whileConditions: [WhileCondition]
    public var captureEndPosition: String.Index?
    
    public init(rule: Rule?,
                phase: Phase,
                patterns: [Rule],
                captureAnchors: [CaptureAnchor],
                scopePath: ScopePath,
                whileConditions: [WhileCondition],
                captureEndPosition: String.Index?)
    {
        self.rule = rule
        self.phase = phase
        self.patterns = patterns
        self.captureAnchors = captureAnchors
        self.scopePath = scopePath
        self.whileConditions = whileConditions
        self.captureEndPosition = captureEndPosition
    }
    
    public var scopeRule: BeginEndRule? {
        return rule as? BeginEndRule
    }
}
