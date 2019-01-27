import Foundation

public struct ParserState {
    public enum Phase {
        case scopeBegin
        case scopeContent
        case scopeEnd
    }
    
    public var rule: Rule?
    public var phase: Phase?
    public var patterns: [Rule]
    public var captureAnchors: [CaptureAnchor]
    public var scopePath: ScopePath
    public var beginMatchResult: Regex.MatchResult?
    public var beginLineIndex: Int?
    public var endPattern: RegexPattern?
    public var endPosition: String.Index?
    
    public init(rule: Rule?,
                phase: Phase?,
                patterns: [Rule],
                captureAnchors: [CaptureAnchor],
                scopePath: ScopePath,
                beginMatchResult: Regex.MatchResult?,
                beginLineIndex: Int?,
                endPattern: RegexPattern?,
                endPosition: String.Index?)
    {
        self.rule = rule
        self.phase = phase
        self.patterns = patterns
        self.captureAnchors = captureAnchors
        self.scopePath = scopePath
        self.beginMatchResult = beginMatchResult
        self.beginLineIndex = beginLineIndex
        self.endPattern = endPattern
        self.endPosition = endPosition
    }
    
    public var scopeRule: ScopeRule? {
        return rule as? ScopeRule
    }
}
