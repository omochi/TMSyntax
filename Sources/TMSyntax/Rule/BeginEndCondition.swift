public struct BeginEndCondition {
    public var begin: RegexPattern
    public var beginCaptures: CaptureAttributes?
    public var end: RegexPattern
    public var endCaptures: CaptureAttributes?
    
    public init(begin: RegexPattern,
                beginCaptures: CaptureAttributes?,
                end: RegexPattern,
                endCaptures: CaptureAttributes?)
    {
        self.begin = begin
        self.beginCaptures = beginCaptures
        self.end = end
        self.endCaptures = endCaptures
    }
}
