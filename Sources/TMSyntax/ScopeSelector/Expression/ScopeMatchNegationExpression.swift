public final class ScopeMatchNegationExpression : ScopeMatchExpression {
    private let expression: ScopeMatchExpression
    
    public init(expression: ScopeMatchExpression) {
        self.expression = expression
    }
    
    public func match(scope: ScopeName) -> Bool {
        return !expression.match(scope: scope)
    }
}
