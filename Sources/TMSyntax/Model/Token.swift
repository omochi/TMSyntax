public struct Token : Equatable {
    public var range: Range<String.Index>
    public var scopePath: [ScopeName]
    
    public init(range: Range<String.Index>,
                scopePath: [ScopeName])
    {
        self.range = range
        self.scopePath = scopePath
    }
}
