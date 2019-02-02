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
}

internal func minFromOptionals<T>(_ a: T?, _ b: T?, cmp: (T, T) -> Bool) -> T? {
    if let a = a {
        if let b = b {
            if cmp(b, a) {
                return b
            }
            // prefer a
            return a
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
