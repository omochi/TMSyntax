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
            guard let range = regexMatch[index],
                !range.isEmpty else
            {
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
            
            if range.lowerBound < top.range.upperBound {
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
        
        return roots
    }
}
