import Foundation
import RichJSONParser
import FineJSON
import enum FineJSON.DecodingError

public enum IncludeTarget : CustomStringConvertible, Decodable, CopyInitializable {
    case repository(String)
    case `self`
    case language(ScopeName)
    
    public var stringValue: String {
        get {
            switch self {
            case .repository(let name): return "#\(name)"
            case .self: return "$self"
            case .language(let name): return "\(name)"
            }
        }
    }
    
    public var description: String {
        return stringValue
    }
    
    public init?(_ string: String) {
        if string.starts(with: "#") {
            let start = string.index(after: string.startIndex)
            self = .repository(String(string[start...]))
        } else if string.starts(with: "$") {
            let start = string.index(after: string.startIndex)
            let str = String(string[start...])
            
            if str == "self" {
                self = .self
            } else {
                return nil
            }
        
        } else {
            let name = ScopeName(string)
            self = .language(name)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let str = try c.decode(String.self)
        guard let cp = IncludeTarget(str) else {
            let m = "invalid target (\(str))"
            throw DecodingError.custom(message: m,
                                       codingPath: decoder.codingPath,
                                       location: decoder.sourceLocation)
        }
        self.init(copy: cp)
    }
}

extension IncludeTarget : CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(self, unlabeledChildren: [])
    }
}
