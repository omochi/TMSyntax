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
        
        public var beginEndBegin: BeginEndBegin? {
            switch self {
            case .beginEndBegin(let b),
                 .beginEndContent(let b),
                 .beginEndEnd(let b, _):
                return b
            default: return nil
            }
        }
        
        public var beginWhile: BeginWhileState? {
            switch self {
            case .beginWhileBegin(let s): return s
            default: return nil
            }
        }
        
        public var rule: Rule? {
            switch self {
            case .rootContent: return nil
            case .match(let s): return s.rule
            case .beginEndBegin(let s): return s.rule
            case .beginEndContent(let s): return s.rule
            case .beginEndEnd(let s, _): return s.rule
            case .beginWhileBegin(let s): return s.rule
            case .captureAnchor: return nil
            }
        }
    }
    
    public struct Match {
        public var rule: MatchRule
        public var matchResult: Regex.MatchResult
        
        public init(rule: MatchRule,
                    matchResult: Regex.MatchResult)
        {
            self.rule = rule
            self.matchResult = matchResult
        }
    }
    
    public struct BeginEndBegin {
        public var rule: BeginEndRule
        public var matchResult: Regex.MatchResult
        public var lineIndex: Int
        public var endPattern: RegexPattern
        public var contentName: ScopeName?
        
        public init(rule: BeginEndRule,
                    matchResult: Regex.MatchResult,
                    lineIndex: Int,
                    endPattern: RegexPattern,
                    contentName: ScopeName?)
        {
            self.rule = rule
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
        public var rule: BeginWhileRule
        public var matchResult: Regex.MatchResult
        public var lineIndex: Int
        public var whilePattern: RegexPattern
        public var contentName: ScopeName?
        
        public init(rule: BeginWhileRule,
                    matchResult: Regex.MatchResult,
                    lineIndex: Int,
                    whilePattern: RegexPattern,
                    contentName: ScopeName?)
        {
            self.rule = rule
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
    
    public var phase: Phase
    public var patterns: [Rule]
    public var captureAnchors: [CaptureAnchor]
    public var scopePath: ScopePath
    public var whileConditions: [WhileCondition]
    public var captureRange: Range<String.Index>?
    
    public init(phase: Phase,
                patterns: [Rule],
                captureAnchors: [CaptureAnchor],
                scopePath: ScopePath,
                whileConditions: [WhileCondition],
                captureRange: Range<String.Index>?)
    {
        self.phase = phase
        self.patterns = patterns
        self.captureAnchors = captureAnchors
        self.scopePath = scopePath
        self.whileConditions = whileConditions
        self.captureRange = captureRange
    }
}
