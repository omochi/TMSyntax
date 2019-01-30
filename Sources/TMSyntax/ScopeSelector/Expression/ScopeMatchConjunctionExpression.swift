public final class ScopeMatchConjunctionExpression : ScopeMatchExpression {
    private let expressions: [ScopeMatchExpression]
    
    public init(expressions: [ScopeMatchExpression]) {
        self.expressions = expressions
    }
    
    public func match(path: ScopePath) -> Bool {
        for e in expressions {
            guard e.match(path: path) else {
                return false
            }
        }
        return true
    }
    
    public var description: String {
        return expressions.map { $0.description }.joined(separator: " ")
    }
}
