import RichJSONParser
import Onigmo

private let maxCodeRegex = try! Regex(pattern: "\\\\x{7fffffff}", options: .ignoreCase)

public final class RegexPattern : Decodable, CustomStringConvertible {
    public let value: String
    public let location: SourceLocation?
    
    private var _regex: Regex?
    public func compile() throws -> Regex {
        return try _regex.ensure {
            try _compile()
        }
    }
    
    private func _compile() throws -> Regex {
        do {
            return try Regex(pattern: value, options: [])
        } catch {
            if let error = error as? OnigmoError {
                if error.status == ONIGERR_TOO_BIG_WIDE_CHAR_VALUE {
                    return try _hackSecondCompile()
                }
            }
            
            throw RegexCompileError(location: location, error: error)
        }
    }
    
    private func _hackSecondCompile() throws -> Regex {
        var value = self.value
        value = maxCodeRegex.replace(string: value) { (match) in
            return "\\x{10ffff}"
        }
        do {
            return try Regex(pattern: value, options: [])
        } catch {
            throw RegexCompileError(location: location, error: error)
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
        var pat: String = value
        
        if pat.count > 40 {
            let patEnd: String.Index = pat.index(pat.startIndex, offsetBy: 40)
            pat = String(pat[..<patEnd])
            pat += "..."
        }
        
        return "\(pat)"
    }
}
