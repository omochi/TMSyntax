import RichJSONParser

public final class RegexPattern : Decodable, CustomStringConvertible {
    public let value: String
    public let location: SourceLocation?
    
    private var _regex: Regex?
    public func compile() throws -> Regex {
        return try _regex.ensure {
            do {
                return try Regex(pattern: value)
            } catch {
                throw RegexCompileError(location: location, error: error)
            }
        }
    }
    
    public init(_ value: String,
                location: SourceLocation?)
    {
        self.value = value
        self.location = location
    }
    
    public convenience init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let value = try c.decode(String.self)
        self.init(value,
                  location: decoder.sourceLocation)
    }
    
    public var description: String {
        var d = "\(value.debugDescription)"
        if let loc = location {
            d += " at \(loc)"
        }
        return d        
    }
}
