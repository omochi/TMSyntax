import Foundation

public struct CaptureAnchor {
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
}
