import XCTest
import TMSyntax

class OnigmoTests: XCTestCase {
    func test1() throws {
        let regex = try Regex(pattern: "[0-9]+")
        
        let string = "abc123abc456"
        var index = string.startIndex
        var m = regex.search(string: string, range: index..<string.endIndex)!
        XCTAssertEqual(string[m[0]], "123")
        index = m[0].upperBound

        m = regex.search(string: string, range: index..<string.endIndex)!
        XCTAssertEqual(string[m[0]], "456")
        index = m[0].upperBound
        
        XCTAssertNil(regex.search(string: string, range: index..<string.endIndex))
    }
    
    func test2() throws {
        let regex = try Regex(pattern: "\\b(?:true|false|null)\\b")
        
        do {
            let s = "false"
            let m = regex.search(string: s, range: s.startIndex..<s.endIndex)!
            XCTAssertEqual(m[0], s.startIndex..<s.endIndex)
        }
        
        do {
            let s = "  false"
            let m = regex.search(string: s, range: s.startIndex..<s.endIndex)!
            XCTAssertEqual(m[0], s.index(s.startIndex, offsetBy: 2)..<s.endIndex)
        }
        
        do {
            let s = "  false\n"
            let m = regex.search(string: s, range: s.startIndex..<s.endIndex)!
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
""")
        
        do {
            let s = "123"
            XCTAssertNotNil(regex.search(string: s, range: s.startIndex..<s.endIndex))
        }
        
        do {
            let s = "-0.789"
            XCTAssertNotNil(regex.search(string: s, range: s.startIndex..<s.endIndex))
        }
        
        do {
            let s = "1.003e+8"
            XCTAssertNotNil(regex.search(string: s, range: s.startIndex..<s.endIndex))
        }
    }
}
