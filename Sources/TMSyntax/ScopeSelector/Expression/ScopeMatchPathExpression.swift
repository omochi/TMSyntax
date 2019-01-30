public final class ScopeMatchPathExpression : ScopeMatchExpression {
    private let pattern: ScopePath
    private let matcher: ScopePathMatcher
    
    public init(pattern: ScopePath,
                matcher: @escaping ScopePathMatcher)
    {
        self.pattern = pattern
        self.matcher = matcher
    }
    
    public func match(path: ScopePath) -> Bool {
        return matcher(pattern, path)
    }
}
