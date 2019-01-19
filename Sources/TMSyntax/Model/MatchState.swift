public struct MatchState {
    public var rule: Rule
    public var scopeName: ScopeName?
    
    public init(rule: Rule,
                scopeName: ScopeName?)
    {
        self.rule = rule
        self.scopeName = scopeName
    }
}
