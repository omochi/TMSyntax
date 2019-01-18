import Foundation

public struct RuleStack {
    public init(_ stack: [Rule]) {
        self.stack = stack
    }
    
    public var stack: [Rule]
    
    public var top: Rule? {
        return stack.last
    }
    
    public mutating func push(_ rule: Rule) {
        stack.append(rule)
    }
    
    public mutating func pop() {
        stack.removeLast()
    }
}
