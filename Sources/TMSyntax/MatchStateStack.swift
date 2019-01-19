public struct MatchStateStack {
    public init() {
        self.items = []
    }
    
    public var items: [MatchState]
    
    public var top: MatchState? {
        return items.last
    }
    
    public mutating func push(_ item: MatchState) {
        items.append(item)
    }
    
    public mutating func pop() {
        items.removeLast()
    }
}
