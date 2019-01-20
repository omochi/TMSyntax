import XCTest
import TMSyntax

class StringTests: XCTestCase {

    func testSplitLines() {
        XCTAssertEqual("".splitLines(), [])
        XCTAssertEqual("a".splitLines(), ["a"])
        XCTAssertEqual("""
abc

""".splitLines(),
                       ["abc\n"])
        XCTAssertEqual("""
abc
def
""".splitLines(),
                       ["abc\n", "def"])
        
        XCTAssertEqual("""
abc

def
""".splitLines(),
                       ["abc\n", "\n", "def"])

    }
    
    func testLineEndIndex() {
        var str = ""
        XCTAssertEqual(str.lineEndIndex, str.endIndex)
        
        str = "aaa"
        XCTAssertEqual(str.lineEndIndex, str.endIndex)
        
        str = "\n"
        XCTAssertEqual(str.lineEndIndex, str.index(before: str.endIndex))
        
        str = "aaaa\n"
        XCTAssertEqual(str.lineEndIndex, str.index(before: str.endIndex))

        str = "aaaa\r"
        XCTAssertEqual(str.lineEndIndex, str.index(before: str.endIndex))

        str = "aaaa\r\n"
        XCTAssertEqual(str.lineEndIndex, str.unicodeScalars.index(str.endIndex, offsetBy: -2))
    }

}
