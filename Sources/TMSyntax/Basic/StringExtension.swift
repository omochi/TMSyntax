import Foundation

// type infer helper
fileprivate func substrUSS(_ us: String.UnicodeScalarView, _ l: String.Index, _ r: String.Index) -> String {
    let range: Range<String.Index> = l..<r
    let susv: Substring.UnicodeScalarView = us[range]
    return String(susv)
}

extension String {
    public func splitLines() -> [String] {
        var result: [String] = []
        
        let view: String.UnicodeScalarView = self.unicodeScalars
        
        var pos: String.Index = startIndex
        var lineStart: String.Index = pos
        while true {
            if pos == endIndex {
                if lineStart != pos {
                    result.append(substrUSS(view, lineStart, pos))
                    lineStart = pos
                }
                break
            }
            
            let c0: Unicode.Scalar = view[pos]
            
            if c0 == .cr {
                pos = view.index(after: pos)
                if pos == endIndex {
                    result.append(substrUSS(view, lineStart, pos))
                    lineStart = pos
                    break
                }
                
                let c1: Unicode.Scalar = view[pos]
                if c1 == .lf {
                    pos = view.index(after: pos)
                    result.append(substrUSS(view, lineStart, pos))
                    lineStart = pos
                } else {
                    result.append(substrUSS(view, lineStart, pos))
                    lineStart = pos
                }
            } else if c0 == .lf {
                pos = view.index(after: pos)
                result.append(substrUSS(view, lineStart, pos))
                lineStart = pos
            } else {
                pos = view.index(after: pos)
            }
        }
        
        return result
    }

    public var lastNewLineIndex: String.Index {
        let view = self.unicodeScalars
        var index = endIndex
        while true {
            if index == startIndex {
                break
            }
            
            let leftIndex = view.index(before: index)
            let c0 = view[leftIndex]
            if c0 == .lf || c0 == .cr {
                index = leftIndex
            } else {
                break
            }
        }
        return index
    }
    
    internal mutating func appendIfPresent(_ str: String?) {
        guard let str = str else {
            return
        }
        self.append(str)
    }
}
