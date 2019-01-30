import Foundation

extension Array {
    public mutating func stableSort(by cmp: (Element, Element) -> Bool) {
        self = self.stableSorted(by: cmp)
    }
    
    public func stableSorted(by cmp: (Element, Element) -> Bool) -> Array<Element> {
        return enumerated()
            .sorted { (a, b) -> Bool in
                if cmp(a.element, b.element) {
                    return true
                }
                if cmp(b.element, a.element) {
                    return false
                }
                return a.offset < b.offset
            }.map { $0.element }
    }
}
