import Foundation

public struct ParserState {
    public enum Phase {
        case pushContentAtEndPosition(ScopeRule)
        case content(ScopeRule)
        
        public var scopeRule: ScopeRule? {
            switch self {
            case .pushContentAtEndPosition(let rule): return rule
            case .content(let rule): return rule
            }
        }
    }
    
    public var phase: Phase?
    public var patterns: [Rule]
    public var captureAnchors: [CaptureAnchor]
    public var scopePath: [ScopeName]
    public var endPattern: RegexPattern?
    public var endPosition: String.Index?
    
    public init(phase: Phase?,
                patterns: [Rule],
                captureAnchors: [CaptureAnchor],
                scopePath: [ScopeName],
                endPattern: RegexPattern?,
                endPosition: String.Index?)
    {
        self.phase = phase
        self.patterns = patterns
        self.captureAnchors = captureAnchors
        self.scopePath = scopePath
        self.endPattern = endPattern
        self.endPosition = endPosition
    }
    
    public var scopeRule: ScopeRule? {
        return phase?.scopeRule
    }
}
