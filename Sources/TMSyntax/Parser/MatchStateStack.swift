public struct MatchStateStack {
    public init() {
        self.items = []
    }
    
    public var items: [MatchState]
    
    public var top: MatchState? {
        get {
            return items.last
        }
        set {
            items[items.count - 1] = newValue!
        }
    }
    
    public mutating func push(_ item: MatchState) {
        items.append(item)
    }
    
    public mutating func pop() {
        if items.isEmpty {
            preconditionFailure("stack underflow")
        }
        items.removeLast()
    }
}
