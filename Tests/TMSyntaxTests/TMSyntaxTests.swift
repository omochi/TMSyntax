import XCTest
import TMSyntax

class TMSyntaxTests: XCTestCase {
    func test1() throws {
        let path = Resources.shared.path("JSON.tmLanguage.json")
        let grammer = try Grammer(contentsOf: path)
        dump(grammer)
    }
}
