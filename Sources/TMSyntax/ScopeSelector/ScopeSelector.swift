public final class ScopeSelector : CustomStringConvertible {
    public struct MatchResult : Equatable {
        public var position: MatchRulePosition
        
        public init(position: MatchRulePosition) {
            self.position = position
        }
    }
    
    public let expressions: [ScopePositionalMatchExpression]
    
    public init(expressions: [ScopePositionalMatchExpression]) {
        self.expressions = expressions
    }
    
    public func match(path: ScopePath) -> MatchResult? {
        for e in expressions {
            if e.match(path: path) {
                return MatchResult(position: e.position)
            }
        }
        return nil
    }
    
    public var description: String {
        return expressions.map { $0.description }.joined(separator: ", ")
    }
}
