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
        XCTAssertEqual(str.lastNewLineIndex, str.endIndex)
        
        str = "aaa"
        XCTAssertEqual(str.lastNewLineIndex, str.endIndex)
        
        str = "\n"
        XCTAssertEqual(str.lastNewLineIndex, str.index(before: str.endIndex))
        
        str = "aaaa\n"
        XCTAssertEqual(str.lastNewLineIndex, str.index(before: str.endIndex))

        str = "aaaa\r"
        XCTAssertEqual(str.lastNewLineIndex, str.index(before: str.endIndex))

        str = "aaaa\r\n"
        XCTAssertEqual(str.lastNewLineIndex, str.unicodeScalars.index(str.endIndex, offsetBy: -2))
    }

}
