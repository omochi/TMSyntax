public struct MatchState {
    public var rule: Rule
    public var patterns: [Rule]
    public var endPattern: RegexPattern?
    public var endPosition: String.Index?
    public var contentName: ScopeName?
    
    public var pushContentNameWhenPop: ScopeName?

    public init(rule: Rule,
                patterns: [Rule],
                endPattern: RegexPattern?,
                endPosition: String.Index?,
                contentName: ScopeName?)
    {
        self.rule = rule
        self.patterns = patterns
        self.endPattern = endPattern
        self.endPosition = endPosition
        
        if let _ = endPattern {
            precondition(rule is ScopeRule)
        }
        
        self.contentName = contentName
    }
    
    public static func createSimpleScope(rule: ScopeRule) -> MatchState {
        return MatchState(rule: rule,
                          patterns: rule.patterns,
                          endPattern: rule.end,
                          endPosition: rule.endPosition,
                          contentName: nil)
    }
}
