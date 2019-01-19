public struct BeginEndCondition {
    public var begin: RegexPattern
    public var end: RegexPattern
    
    public init(begin: RegexPattern,
                end: RegexPattern)
    {
        self.begin = begin
        self.end = end
    }
}
