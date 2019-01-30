public protocol ScopeMatchExpression {
    func match(path: ScopePath) -> Bool
}


