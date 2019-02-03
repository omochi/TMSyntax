import Foundation

public final class CaptureAnchor {
    public var captureIndex: Int
    public var attribute: CaptureAttribute?
    public var range: Range<String.Index>
    public var children: [CaptureAnchor]
    
    public init(captureIndex: Int,
                attribute: CaptureAttribute?,
                range: Range<String.Index>,
                children: [CaptureAnchor],
                line: String,
                matchResult: Regex.MatchResult) throws
    {
        func resolve(attribute: CaptureAttribute) throws -> CaptureAttribute {
            var attribute = attribute
            attribute.name = try attribute.resolveName(line: line,
                                                       matchResult: matchResult)
            return attribute
        }
        
        self.captureIndex = captureIndex
        self.attribute = try attribute
            .map { try resolve(attribute: $0) }
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
    
    public static func build(matchResult: Regex.MatchResult,
                             captures: CaptureAttributes?,
                             line: String)
        throws -> [CaptureAnchor]
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
        while index < matchResult.count {
            guard let range = matchResult[index] else
            {
                index += 1
                continue
            }
            
            guard let top = top else {
                let anchor = try CaptureAnchor(captureIndex: index,
                                               attribute: _attr(index),
                                               range: range,
                                               children: [],
                                               line: line,
                                               matchResult: matchResult)
                roots.append(anchor)
                stack.append(anchor)
                index += 1
                continue
            }
            
            if range.upperBound <= top.range.upperBound {
                let anchor = try CaptureAnchor(captureIndex: index,
                                               attribute: _attr(index),
                                               range: range,
                                               children: [],
                                               line: line,
                                               matchResult: matchResult)
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
