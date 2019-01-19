import Foundation

public enum IncludeTarget : CustomStringConvertible, Decodable, CopyInitializable {
    case repository(String)
    case `self`
    
    public var stringValue: String {
        get {
            switch self {
            case .repository(let name): return "#\(name)"
            case .self: return "$self"
            }
        }
    }
    
    public var description: String {
        return stringValue
    }
    
    public init?(_ string: String) {
        if string.starts(with: "#") {
            let s = string.index(after: string.startIndex)
            self = .repository(String(string[s...]))
        } else if string == "$self" {
            self = .self
        } else {
            return nil
        }
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let str = try c.decode(String.self)
        guard let cp = IncludeTarget(str) else {
            throw DecodingError(location: decoder.sourceLocation,
                                "invalid target (\(str))")
        }
        self.init(copy: cp)
    }
}

extension IncludeTarget : CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(self, unlabeledChildren: [])
    }
}
