import XCTest
import TMSyntax

class OnigmoTests: XCTestCase {
    func test1() throws {
        let regex = try Regex(pattern: "[0-9]+", options: [])
        
        let string = "abc123abc456"
        var index = string.startIndex
        var m = regex.search(string: string, range: index..<string.endIndex, options: [])!
        XCTAssertEqual(string[m[]], "123")
        index = m[].upperBound

        m = regex.search(string: string, range: index..<string.endIndex, options: [])!
        XCTAssertEqual(string[m[]], "456")
        index = m[].upperBound
        
        XCTAssertNil(regex.search(string: string, range: index..<string.endIndex, options: []))
    }
    
    func test2() throws {
        let regex = try Regex(pattern: "\\b(?:true|false|null)\\b", options: [])
        
        do {
            let s = "false"
            let m = regex.search(string: s, range: s.startIndex..<s.endIndex, options: [])!
            XCTAssertEqual(m[0], s.startIndex..<s.endIndex)
        }
        
        do {
            let s = "  false"
            let m = regex.search(string: s, range: s.startIndex..<s.endIndex, options: [])!
            XCTAssertEqual(m[0], s.index(s.startIndex, offsetBy: 2)..<s.endIndex)
        }
        
        do {
            let s = "  false\n"
            let m = regex.search(string: s, range: s.startIndex..<s.endIndex, options: [])!
            XCTAssertEqual(m[0], s.index(s.startIndex, offsetBy: 2)..<s.index(s.endIndex, offsetBy: -1))
        }
    }
    
    func test3() throws {
        let regex = try Regex(pattern: """
(?x)        # turn on extended mode
  -?        # an optional minus
  (?:
    0       # a zero
    |       # ...or...
    [1-9]   # a 1-9 character
   \\d*     # followed by zero or more digits
  )
  (?:
    (?:
     \\.    # a period
     \\d+   # followed by one or more digits
    )?
    (?:
      [eE]  # an e character
      [+-]? # followed by an option +/-
     \\d+   # followed by one or more digits
    )?      # make exponent optional
  )?        # make decimal portion optional
""", options: [])
        
        do {
            let s = "123"
            XCTAssertNotNil(regex.search(string: s, range: s.startIndex..<s.endIndex, options: []))
        }
        
        do {
            let s = "-0.789"
            XCTAssertNotNil(regex.search(string: s, range: s.startIndex..<s.endIndex, options: []))
        }
        
        do {
            let s = "1.003e+8"
            XCTAssertNotNil(regex.search(string: s, range: s.startIndex..<s.endIndex, options: []))
        }
    }
    
    func testReplace() throws {
        let regex = try Regex(pattern: "a(\\d+)", options: [])
        
        let string = "bba1bba2a3"
        let rep = regex.replace(string: string) { (match) in
            let n = Int(string[match[1]!])!
            return Array(repeating: "x", count: n).joined()
        }
        
        XCTAssertEqual(rep, "bbxbbxxxxx")
    }
    
    func testComplex1() throws {
        let pattern = """
(?x)
((?:(?:final|abstract|public|private|protected|static)\\s+)*)
(function)\\s+
(?i:
(__(?:call|construct|debugInfo|destruct|get|set|isset|unset|toString|
clone|set_state|sleep|wakeup|autoload|invoke|callStatic))
|([a-zA-Z_\\x{7f}-\\x{10ffff}][a-zA-Z0-9_\\x{7f}-\\x{10ffff}]*)
)
\\s*(\\()
"""
        let regex = try Regex(pattern: pattern, options: [])
        let string = "public function __construct(){}"
        let m = regex.search(string: string, range: string.startIndex..<string.endIndex, options: [])
        XCTAssertNotNil(m)
    }
    
    func testNamedCapture() throws {
        let regex = try Regex(pattern: """
(?x)
  (?<ft>
    [a-zA-Z_][\\w.]*
  )
  [ \\t]*
  (?:([a-zA-Z_][\\w.]*)[ \\t]*)?
"""
            , options: [.captureGroup])
        let string = "  1: string message"
        let m = regex.search(string: string,
                             range: string.startIndex..<string.endIndex,
                             globalPosition: nil,
                             options: [])
        XCTAssertEqual(m!.count, 3)
        XCTAssertEqual(String(string[m![1]!]), "string")
        XCTAssertEqual(String(string[m![2]!]), "message")
    }
    
    func _testBigChar() throws {
        do {
            _ = try Regex(pattern: "\\x{7FFFFFFF}", options: [])
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testRange() throws {
        let regex = try Regex(pattern: "abc", options: [])
        let string = "xxxabcxxx"
        let m = regex.search(string: string,
                             range: string.index(at: 3)..<string.index(at: 6), options: [])
        XCTAssertEqual(m![], string.index(at: 3)..<string.index(at: 6))
    }
    
    func testWordBound() throws {
        let regex = try Regex(pattern: "<--(\\\"?)SQL\\b\\1", options: [])
        let string = "<% <--SQL SELECT"
        var m = regex.search(string: string, range: string.index(at: 0)..<string.index(at: 16), options: [])
        XCTAssertNotNil(m)
        
        m = regex.search(string: string, range: string.index(at: 3)..<string.index(at: 9), options: [])
        XCTAssertNotNil(m)
    }
    
    func testEndAnchor() throws {
        let regex = try Regex(pattern: "a$", options: [])
        var string = "xab"
        var m = regex.search(string: string, range: string.index(at: 0)..<string.index(at: 2), options: [])
        XCTAssertNil(m)
        
        string = "xa"
        m = regex.search(string: string, range: string.index(at: 0)..<string.index(at: 2), options: [])
        XCTAssertNotNil(m)
    }
    
    func testSubstring() throws {
        let regex = try Regex(pattern: "e", options: [])
        let string = "abcdefgh"
        let m = regex.search(string: string[string.index(at: 2)..<string.index(at: 7)],
                             range: string.index(at: 3)..<string.index(at: 6),
                             options: [])
        XCTAssertEqual(m?[0], string.index(at: 4)..<string.index(at: 5))
    }
    
    func testNullGlobalPos() throws {
        let regex = try Regex(pattern: "\\Ga", options: [])
        let string = "abcdefgh"
        var m = regex.search(string: string,
                             range: string.startIndex..<string.endIndex,
                             globalPosition: nil,
                             options: [])
        XCTAssertNil(m)
        
        m = regex.search(string: string,
                         range: string.startIndex..<string.endIndex,
                         globalPosition: string.startIndex,
                         options: [])
        XCTAssertEqual(m?[0], string.index(at: 0)..<string.index(at: 1))
    }
    
}
