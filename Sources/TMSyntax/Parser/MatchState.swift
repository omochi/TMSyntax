public struct MatchState {
    public var rule: Rule
    public var patterns: [Rule]
    public var scopeName: ScopeName?
    public var endPattern: RegexPattern?
    public var endPosition: String.Index?

    public init(rule: Rule,
                patterns: [Rule],
                scopeName: ScopeName?,
                endPattern: RegexPattern?,
                endPosition: String.Index?)
    {
        self.rule = rule
        self.patterns = patterns
        self.scopeName = scopeName
        self.endPattern = endPattern
        self.endPosition = endPosition
    }
    
    public static func createSimpleScope(rule: ScopeRule) -> MatchState {
        return MatchState(rule: rule,
                          patterns: rule.patterns,
                          scopeName: rule.scopeName,
                          endPattern: rule.end,
                          endPosition: rule.endPosition)
    }
}
