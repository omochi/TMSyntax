public final class ScopeMatchDisjunctionExpression : ScopeMatchExpression {
    private let expressions: [ScopeMatchExpression]
    
    public init(expressions: [ScopeMatchExpression]) {
        self.expressions = expressions
    }
    
    public func match(scope: ScopeName) -> Bool {
        for e in expressions {
            if e.match(scope: scope) {
                return true
            }
        }
        return false
    }
}
