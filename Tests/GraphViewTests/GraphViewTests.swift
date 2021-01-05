import XCTest
@testable import GraphView

final class GraphViewTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(GraphView().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
