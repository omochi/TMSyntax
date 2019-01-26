import Foundation

public final class CaptureAnchor {
    public var attribute: CaptureAttribute?
    public var range: Range<String.Index>
    public var children: [CaptureAnchor]
    
    public init(attribute: CaptureAttribute?,
                range: Range<String.Index>,
                children: [CaptureAnchor])
    {
        self.attribute = attribute
        self.range = range
        self.children = children
    }
    
    public var hasNoScopeSelf: Bool {
        guard let attr = attribute else {
            return true
        }
        return attr.name == nil &&
            attr.patterns.isEmpty
    }

    public func removeNoScopeNode() {
        _ = _removeNoScopeNode()
    }
    
    private func _removeNoScopeNode() -> Bool {
        var newChildren: [CaptureAnchor] = []
        for c in self.children {
            if c._removeNoScopeNode() {
                continue
            }
            newChildren.append(c)
        }
        self.children = newChildren
        return hasNoScopeSelf && children.isEmpty
    }
    
    public static func build(regexMatch: Regex.Match,
                             captures: CaptureAttributes?) -> [CaptureAnchor]
    {
        func _attr(_ index: Int) -> CaptureAttribute? {
            guard let captures = captures,
                let attr = captures.dictionary["\(index)"] else
            {
                return nil
            }
            return attr
        }
                
        var roots: [CaptureAnchor] = []
        var stack: [CaptureAnchor] = []
        
        var top: CaptureAnchor? {
            get { return stack.last }
        }
        
        var index = 0
        while index < regexMatch.count {
            guard let range = regexMatch[index] else
            {
                index += 1
                continue
            }
            
            guard let top = top else {
                let anchor = CaptureAnchor(attribute: _attr(index),
                                           range: range,
                                           children: [])
                roots.append(anchor)
                stack.append(anchor)
                index += 1
                continue
            }
            
            if range.upperBound <= top.range.upperBound {
                let anchor = CaptureAnchor(attribute: _attr(index),
                                           range: range,
                                           children: [])
                top.children.append(anchor)
                stack.append(anchor)
                index += 1
            } else {
                stack.removeLast()
            }
        }
        
        roots.forEach { $0.removeNoScopeNode() }
        return roots
    }
}
