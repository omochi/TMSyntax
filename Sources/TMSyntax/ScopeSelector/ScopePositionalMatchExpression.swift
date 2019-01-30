import Foundation

public final class ScopePositionalMatchExpression : CustomStringConvertible {
    public let position: ScopeMatchPosition
    public let expression: ScopeMatchExpression
    
    public init(position: ScopeMatchPosition,
                expression: ScopeMatchExpression)
    {
        self.position = position
        self.expression = expression
    }
    
    public func match(path: ScopePath) -> Bool {
        return expression.match(path: path)
    }
    
    public var description: String {
        var d = expression.description
        switch position {
        case .none: break
        case .left: d = "L:" + d
        case .right: d = "R:" + d
        }
        return d
    }
}
