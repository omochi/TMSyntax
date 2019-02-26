import XCTest
import TMSyntax

class CaptureAnchorTests: XCTestCase {
    class StringTree : Equatable, CustomStringConvertible {
        var string: String
        var children: [StringTree]
        
        init(_ string: String,
             _ children: [StringTree])
        {
            self.string = string
            self.children = children
        }
        
        static func == (a: CaptureAnchorTests.StringTree, b: CaptureAnchorTests.StringTree) -> Bool {
            return a.string == b.string &&
                a.children == b.children
        }
        
        var description: String {
            let cs = children.map { "\($0)" }.joined(separator: ", ")
            return "(\(string), [\(cs)])"
        }
    }
    
    func test1() throws {
        let s = "abcdefghijk"
        
        // ((ab)c(de(f(g)))(h(ij)k))
        let ranges: [Range<String.Index>] = [
            s.index(at: 0)..<s.index(at: 11),
            s.index(at: 0)..<s.index(at: 2),
            s.index(at: 3)..<s.index(at: 7),
            s.index(at: 5)..<s.index(at: 7),
            s.index(at: 6)..<s.index(at: 7),
            s.index(at: 7)..<s.index(at: 11),
            s.index(at: 8)..<s.index(at: 10)
        ]
        
        let attr = CaptureAttribute(sourceLocation: nil, name: ScopeName("a"), patterns: [])
        let anchors = try CaptureAnchor.build(matchResult: Regex.MatchResult(ranges: ranges),
                                              captures: CaptureAttributes(dictionary: [
                                                "1": attr,
                                                "2": attr,
                                                "3": attr,
                                                "4": attr,
                                                "5": attr,
                                                "6": attr,
                                                ]),
                                              line: "")
        func map(_ anchor: CaptureAnchor) -> StringTree {
            return StringTree(String(s[anchor.range]),
                              anchor.children.map { map($0) })
        }
        
        let actual = anchors.map { map($0) }
        
        let expect: [StringTree] = [StringTree("abcdefghijk",[
            StringTree("ab", []),
            StringTree("defg", [
                StringTree("fg", [
                    StringTree("g", [])
                    ])
                ]),
            StringTree("hijk", [
                StringTree("ij", [])
                ])
            ])]
        
        XCTAssertEqual(actual, expect)
    }

}
