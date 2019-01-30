public protocol ScopeMatchExpression : CustomStringConvertible {
    func match(path: ScopePath) -> Bool
}


