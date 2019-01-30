public final class ScopeMatchDisjunctionExpression : ScopeMatchExpression {
    private let expressions: [ScopeMatchExpression]
    
    public init(expressions: [ScopeMatchExpression]) {
        self.expressions = expressions
    }
    
    public func match(path: ScopePath) -> Bool {
        for e in expressions {
            if e.match(path: path) {
                return true
            }
        }
        return false
    }
}
