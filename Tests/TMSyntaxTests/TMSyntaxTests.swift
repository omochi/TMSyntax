import XCTest
import TMSyntax
import OrderedDictionary

class TMSyntaxTests: XCTestCase {
    func test1() throws {
        let path = Resources.shared.path("JSON.tmLanguage.json")
        let grammer = try Grammer(contentsOf: path)
        
        XCTAssert((grammer.rule.patterns[0] as! IncludeRule).target ===
                (grammer.rule.repository!.dict["value"]))
    }
}
