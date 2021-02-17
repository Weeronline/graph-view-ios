import XCTest
@testable import GraphView
#if canImport(UIKit)

final class GraphViewTests: XCTestCase {
    let graphView = GraphView(frame: CGRect.zero)

    override func setUpWithError() throws {
        UIGraphicsBeginImageContext(CGSize(width: 100.0, height: 100.0))
                
        let items: [CGFloat] = [0.1, 0.2, 0.3, 0.5, 0.8, 0.7, 0.8, 0.7, 0.6, 0.5]
        
        let graphViewDataSourceTests = GraphViewDataSourceTests(items: items)
        let graphViewDelegateTests = GraphViewDelegateTests(barsWidth: 20)
        
        graphView.dataSource = graphViewDataSourceTests
        graphView.delegate = graphViewDelegateTests
        
        graphView.draw(CGRect.zero)
    }
    
    override func tearDownWithError() throws {
        UIGraphicsEndImageContext()
    }
    
    func testDataSourceItems() {
        XCTAssertEqual(10, graphView.numberOfItems)
        XCTAssertEqual(0.1, graphView.item(atIndex: 0))
        XCTAssertEqual(0.8, graphView.item(atIndex: 4))
        XCTAssertEqual(0.5, graphView.item(atIndex: 9))
    }
    
    func testDelegateBarsWidth() {
        XCTAssertEqual(20, graphView.barWidth)
    }

    static var allTests = [
        ("testDataSourceItems", testDataSourceItems),
        ("testDelegateBarsWidth", testDelegateBarsWidth),
    ]
}

class GraphViewDataSourceTests: GraphViewDataSource {
    let items: [CGFloat]
    
    init(items: [CGFloat]) {
        self.items = items
    }
    
    func numberOfItems(in graphView: GraphView) -> Int {
        return items.count
    }
    
    func graphView(_ graphView: GraphView, pointForItemAt index: Int) -> CGFloat {
        return items[index]
    }
}

class GraphViewDelegateTests: GraphViewDelegate {
    let barsWidth: CGFloat
    
    init(barsWidth: CGFloat) {
        self.barsWidth = barsWidth
    }
    
    func graphView(_ graphView: GraphView, widthForBarAt index: Int) -> CGFloat {
        return barsWidth
    }
}

#endif
