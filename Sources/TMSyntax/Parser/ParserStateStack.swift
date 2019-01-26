public struct ParserStateStack {
    public var stack: [ParserState]
    
    public var top: ParserState? {
        get {
            return stack[stack.count - 1]
        }
        set {
            stack[stack.count - 1] = newValue!
        }
    }
    
    public init(_ stack: [ParserState]) {
        self.stack = stack
    }
}
