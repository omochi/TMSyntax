public struct Token : Equatable {
    public var range: Range<String.Index>
    public var scopePath: ScopePath
    
    public init(range: Range<String.Index>,
                scopePath: ScopePath)
    {
        self.range = range
        self.scopePath = scopePath
    }
}
