public struct Token : Equatable {
    public var range: Range<String.Index>
    public var scopes: [ScopeName]
    
    public init(range: Range<String.Index>,
                scopes: [ScopeName])
    {
        self.range = range
        self.scopes = scopes
    }
}
