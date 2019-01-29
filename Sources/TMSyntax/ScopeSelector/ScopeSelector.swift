public final class ScopeSelector {
    public struct MatchResult : Equatable {
        public var position: ScopeMatchPosition
        
        public init(position: ScopeMatchPosition) {
            self.position = position
        }
    }
    
    public let expressions: [ScopePositionalMatchExpression]
    
    public init(expressions: [ScopePositionalMatchExpression]) {
        self.expressions = expressions
    }
    
    public func match(scope: ScopeName) -> MatchResult? {
        for e in expressions {
            if e.match(scope: scope) {
                return MatchResult(position: e.position)
            }
        }
        return nil
    }
}
