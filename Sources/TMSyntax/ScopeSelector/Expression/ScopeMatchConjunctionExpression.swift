public final class ScopeMatchConjunctionExpression : ScopeMatchExpression {
    private let expressions: [ScopeMatchExpression]
    
    public init(expressions: [ScopeMatchExpression]) {
        self.expressions = expressions
    }
    
    public func match(scope: ScopeName) -> Bool {
        for e in expressions {
            guard e.match(scope: scope) else {
                return false
            }
        }
        return true
    }
}
