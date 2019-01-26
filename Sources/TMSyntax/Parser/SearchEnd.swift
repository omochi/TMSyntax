import Foundation

public enum SearchEnd {
    case beginCapture(CaptureAnchor)
    case endPosition(String.Index)
    case line(String.Index)
    
    public var position: String.Index {
        switch self {
        case .beginCapture(let anchor):
            return anchor.range.lowerBound
        case .endPosition(let position),
             .line(let position):
            return position
        }
    }
}
