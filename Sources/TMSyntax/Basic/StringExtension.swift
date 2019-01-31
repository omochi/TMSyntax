import Foundation

extension String {
    public func splitLines() -> [String] {
        var result = [String]()
        
        let view = self.unicodeScalars
        
        var pos = startIndex
        var lineStart = pos
        while true {
            if pos == endIndex {
                if lineStart != pos {
                    result.append(String(view[lineStart..<pos]))
                    lineStart = pos
                }
                break
            }
            
            let c0 = view[pos]
            
            if c0 == .cr {
                pos = view.index(after: pos)
                if pos == endIndex {
                    result.append(String(view[lineStart..<pos]))
                    lineStart = pos
                    break
                }
                
                let c1 = view[pos]
                if c1 == .lf {
                    pos = view.index(after: pos)
                    result.append(String(view[lineStart..<pos]))
                    lineStart = pos
                } else {
                    result.append(String(view[lineStart..<pos]))
                    lineStart = pos
                }
            } else if c0 == .lf {
                pos = view.index(after: pos)
                result.append(String(view[lineStart..<pos]))
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
}
