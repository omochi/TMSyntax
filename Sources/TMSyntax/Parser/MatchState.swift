public struct MatchState {
    public var rule: Rule
    public var scopeName: ScopeName?
    public var endPattern: RegexPattern?
    
    public init(rule: Rule,
                scopeName: ScopeName?,
                endPattern: RegexPattern?)
    {
        self.rule = rule
        self.scopeName = scopeName
        self.endPattern = endPattern
    }
}
