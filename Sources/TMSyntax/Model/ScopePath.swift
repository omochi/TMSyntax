import Foundation

public struct ScopePath :
    Equatable, Hashable, CustomStringConvertible
{
    public var items: [ScopeName]
    
    public init(_ items: [ScopeName]) {
        precondition(!items.isEmpty)
        self.items = items
    }
    
    public var description: String {
        return items.description
    }
    
    public var top: ScopeName {
        return items[items.count - 1]
    }
    
    public mutating func push(_ name: ScopeName) {
        items.append(name)
    }
    
    public mutating func pop() {
        items.removeLast()
        precondition(!items.isEmpty)
    }
}
