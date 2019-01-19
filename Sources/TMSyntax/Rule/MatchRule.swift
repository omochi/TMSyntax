import Foundation
import RichJSONParser

public final class MatchRule : Rule {
    public let pattern: RegexPattern
   
    public override var scopeName: ScopeName? {
        return _scopeName
    }
    public let _scopeName: ScopeName?
    
    public var captures: CaptureAttributes?
    
    public init(sourceLocation: SourceLocation?,
                pattern: RegexPattern,
                scopeName: ScopeName?,
                captures: CaptureAttributes?)
    {
        self.pattern = pattern
        self._scopeName = scopeName
        self.captures = captures
        super.init(sourceLocation: sourceLocation)
    }
    
    public required convenience init(from decoder: Decoder) throws {
        fatalError()
    }
}
