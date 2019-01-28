import Foundation
import RichJSONParser
import FineJSON
import enum FineJSON.DecodingError

public enum IncludeTarget : CustomStringConvertible, Decodable, CopyInitializable {
    case repository(String)
    case `self`
    case language(ScopeName, String?)
    
    public var stringValue: String {
        get {
            switch self {
            case .repository(let name): return "#\(name)"
            case .self: return "$self"
            case .language(let lang, let name):
                var s = "\(lang)"
                if let name = name {
                    s += "#\(name)"
                }
                return s
            }
        }
    }
    
    public var description: String {
        return stringValue
    }
    
    public init?(_ string: String) {
        if let index = string.firstIndex(where: { $0 == Character("#") }) {
            if index == string.startIndex {
                let st = string.index(after: index)
                self = .repository(String(string[st...]))
            } else {
                let lang = String(string[..<index])
                
                let st = string.index(after: index)
                guard st < string.endIndex else {
                    return nil
                }
                
                let name = String(string[st...])
                self = .language(ScopeName(lang), name)
            }
        } else if string.starts(with: "$") {
            let start = string.index(after: string.startIndex)
            let str = String(string[start...])
            
            if str == "self" || str == "base" {
                self = .self
            } else {
                return nil
            }
        } else {
            let name = ScopeName(string)
            self = .language(name, nil)
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
