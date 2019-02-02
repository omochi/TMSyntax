import Foundation
import RichJSONParser

public final class MatchRule : Rule {
    public let pattern: RegexPattern
   
    private let scopeName: ScopeName?
    
    public var captures: CaptureAttributes?
    
    public init(sourceLocation: SourceLocation?,
                isEnabled: Bool,
                pattern: RegexPattern,
                scopeName: ScopeName?,
                captures: CaptureAttributes?)
    {
        self.pattern = pattern
        self.scopeName = scopeName
        self.captures = captures
        super.init(sourceLocation: sourceLocation,
                   isEnabled: isEnabled)
    }
    
    public required convenience init(from decoder: Decoder) throws {
        fatalError()
    }
    
    public override var switcher: Rule.Switcher {
        return .match(self)
    }
    
    public func resolveScopeName(line: String,
                                 matchResult: Regex.MatchResult)
        throws -> ScopeName?
    {
        return try scopeName.map {
            try BeginEndRule.resolveName(name: $0,
                                           line: line,
                                           matchResult: matchResult)
        }
    }
}
