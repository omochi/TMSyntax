public final class ScopeMatchNameExpression : ScopeMatchExpression {
    private let pattern: ScopeName
    private let matcher: ScopeNameMatcher
    
    public init(pattern: ScopeName,
                matcher: @escaping ScopeNameMatcher)
    {
        self.pattern = pattern
        self.matcher = matcher
    }
    
    public func match(scope: ScopeName) -> Bool {
        return matcher(pattern, scope)
    }
}
