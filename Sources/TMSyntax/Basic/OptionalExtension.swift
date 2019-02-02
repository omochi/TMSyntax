import Foundation

internal extension Optional {
    mutating func ensure(_ f: () throws -> Wrapped) rethrows -> Wrapped {
        if let x = self {
            return x
        }
        
        let x = try f()
        self = x
        return x
    }
    
    func mapToString(_ f: (Wrapped) -> String) -> String {
        guard let x = self else {
            return ""
        }
        return f(x)
    }
    
    func mapToArray<U>(_ f: (Wrapped) throws -> U) rethrows -> [U] {
        guard let t = self else {
            return []
        }
        let u = try f(t)
        return [u]
    }
    
    func squashed(_ b: Wrapped?, f: (Wrapped, Wrapped) throws -> Wrapped) rethrows -> Wrapped? {
        let a = self
        if let a = a {
            if let b = b {
                return try f(a, b)
            } else {
                return a
            }
        } else {
            if let b = b {
                return b
            } else {
                return nil
            }
        }
    }
    
    mutating func squash(_ b: Wrapped?, f: (Wrapped, Wrapped) throws -> Wrapped) rethrows {
        self = try squashed(b, f: f)
    }
}
