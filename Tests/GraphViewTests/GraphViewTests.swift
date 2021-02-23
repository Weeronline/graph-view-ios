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
        
        graphView.reloadData()
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
    
    func testBorderColors() {
        let firstBorder = graphView.subviews.first { (view) -> Bool in
            view.accessibilityIdentifier == "GraphVerticalLine0"
        }
        XCTAssertEqual(UIColor.red, firstBorder?.backgroundColor)
    }
    
    func testHorizontalLines() {
        let horizontalViews = graphView.subviews.filter { (view) -> Bool in
            return view.accessibilityIdentifier?.contains("GraphHorizontalLine") == true
        }
        
        XCTAssertEqual(horizontalViews.count, 3)
        
        let firstBarView = horizontalViews.first { (view) -> Bool in
            view.accessibilityIdentifier == "GraphHorizontalLine0"
        }
        XCTAssertEqual(firstBarView?.backgroundColor, UIColor.white)
        
        let borderView = horizontalViews.first { (view) -> Bool in
            view.accessibilityIdentifier == "GraphHorizontalLine1"
        }
        XCTAssertEqual(borderView?.backgroundColor, UIColor.blue)
        
        let lastBarView = horizontalViews.first { (view) -> Bool in
            view.accessibilityIdentifier == "GraphHorizontalLine2"
        }
        XCTAssertEqual(lastBarView?.backgroundColor, UIColor.white)
    }
    
    static var allTests = [
        ("testDataSourceItems", testDataSourceItems),
        ("testDelegateBarsWidth", testDelegateBarsWidth),
        ("testBorderColors", testBorderColors),
        ("testHorizontalLines", testHorizontalLines),
    ]
}

class GraphViewDataSourceTests: GraphViewDataSource {
    let items: [CGFloat]
    
    var horizontalLines: [CGFloat] = [0.0, 0.5, 1.0]
    
    init(items: [CGFloat]) {
        self.items = items
    }
    
    func numberOfItems(in graphView: GraphView) -> Int {
        return items.count
    }
    
    func graphView(_ graphView: GraphView, pointForItemAt index: Int) -> CGFloat {
        return items[index]
    }
    
    func graphColor(in graphView: GraphView) -> UIColor {
        UIColor.green
    }
    
    func graphView(_ graphView: GraphView, colorForVerticalLineAt index: Int) -> UIColor? {
        return index == items.count || index == 0 ? .red : .blue
    }
    
    func numberOfHorizontalLines(in graphView: GraphView) -> Int {
        return horizontalLines.count
    }
    
    func graphView(_ graphView: GraphView, valueForHorizontalBarAt index: Int) -> CGFloat {
        horizontalLines[index]
    }
    
    func graphView(_ graphView: GraphView, colorForHorizontalBarAt index: Int) -> UIColor {
        (index == horizontalLines.count - 1) || index == 0 ? .white : .blue
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
