public final class ScopeMatchNegationExpression : ScopeMatchExpression {
    private let expression: ScopeMatchExpression
    
    public init(expression: ScopeMatchExpression) {
        self.expression = expression
    }
    
    public func match(path: ScopePath) -> Bool {
        return !expression.match(path: path)
    }
}
