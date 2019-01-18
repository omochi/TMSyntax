import Foundation

public enum IncludeTarget : CustomStringConvertible {
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
}

extension IncludeTarget : CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(self, unlabeledChildren: [])
    }
}
