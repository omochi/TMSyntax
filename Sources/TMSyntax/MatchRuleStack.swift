import Foundation

public struct MatchRuleStack {
    public struct Item {
        public var rule: Rule
        public var scopeName: ScopeName?
        
        public init(rule: Rule,
                    scopeName: ScopeName?)
        {
            self.rule = rule
            self.scopeName = scopeName
        }
    }
    
    public init() {
        self.items = []
    }
    
    public var items: [Item]
    
    public var top: Item? {
        return items.last
    }
    
    public mutating func push(_ item: Item) {
        items.append(item)
    }
    
    public mutating func pop() {
        items.removeLast()
    }
}
