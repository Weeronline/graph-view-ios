#if canImport(UIKit)
import UIKit

@objc
public protocol GraphViewDataSource: AnyObject {
    func numberOfItems(in graphView: GraphView) -> Int
    func graphView(_ graphView: GraphView, pointForItemAt index: Int) -> CGFloat
    func graphColor(in graphView: GraphView) -> UIColor
    @objc optional func graphBorderColor(in graphView: GraphView) -> UIColor

    @objc optional func graphView(_ graphView: GraphView, colorForVerticalLineAt index: Int) -> UIColor?
    @objc optional func graphView(_ graphView: GraphView, colorForVerticalBarBackgroundAt index: Int) -> UIColor?
    @objc optional func graphView(_ graphView: GraphView, layerForVerticalBarBackgroundAt index: Int) -> CALayer?

    @objc optional func numberOfHorizontalLines(in graphView: GraphView) -> Int
    @objc optional func graphView(_ graphView: GraphView, valueForHorizontalBarAt index: Int) -> CGFloat
    @objc optional func graphView(_ graphView: GraphView, colorForHorizontalBarAt index: Int) -> UIColor

}

@objc
public protocol GraphViewDelegate: AnyObject {
    @objc optional func graphView(_ graphView: GraphView, widthForBarAt index: Int) -> CGFloat
    @objc optional func graphView(_ graphView: GraphView, didSelectBarAt index: Int)
}

public class GraphView: UIView {

    private let maxValue = 1
    private let borderWidth: CGFloat = 1.0
    private var items = [CGFloat]()
    
    @IBOutlet weak var dataSource: GraphViewDataSource?
    @IBOutlet weak var delegate: GraphViewDelegate?

    open private(set) var numberOfItems: Int = 0
    
    private(set) var isScrolling = false
    private(set) var barWidth: CGFloat = 60
    
    public override var bounds: CGRect {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public override func draw(_ rect: CGRect) {
        resetView()
                
        guard let dataSource = dataSource else {
          return
        }
        
        
        barWidth = delegate?.graphView?(self, widthForBarAt: 0) ?? 20.0
        numberOfItems = dataSource.numberOfItems(in: self)
                
        items = (0..<numberOfItems).map { (index) in
            dataSource.graphView(self, pointForItemAt: index)
        }
        
        let verticalLinesColors = (0...numberOfItems).map { (index) in
            dataSource.graphView?(self, colorForVerticalLineAt: index)
        }
        
        let verticalLinesLayers = (0...numberOfItems).map { (index) in
            dataSource.graphView?(self, layerForVerticalBarBackgroundAt: index)
        }
        
        let backgroundColors = (0..<numberOfItems).map { (index) in
            dataSource.graphView?(self, colorForVerticalBarBackgroundAt: index)
        }
        
        let numberOfHorizontalLines = dataSource.numberOfHorizontalLines?(in: self) ?? 0
        
        let horizontalLines: [(value: CGFloat, color: UIColor)] = (0..<numberOfHorizontalLines).compactMap { (index) in
            if let value = dataSource.graphView?(self, valueForHorizontalBarAt: index),
               let color = dataSource.graphView?(self, colorForHorizontalBarAt: index) {
                return (value: value, color: color)
            }
            return nil
        }
        
        addGraphVerticalBackgroundBars(size: rect.size, layers: verticalLinesLayers)
        addGraphHorizontalLines(size: rect.size, horizontalLines: horizontalLines)
        addGraphVerticalLines(size: rect.size, borderColors: verticalLinesColors, layers: verticalLinesLayers, backgroundColors: backgroundColors)
        addGraphPoints(size: rect.size, graphColor: dataSource.graphColor(in: self), borderColor: dataSource.graphBorderColor?(in: self))
    }
    
    public func reloadData() {
        setNeedsDisplay()
    }
    
    // MARK: - Drawing
    
    private func resetView() {
        items.removeAll()
        subviews.forEach({ (view) in
            view.removeFromSuperview()
        })
    }
    
    private func fixPoints(size: CGSize) -> [CGPoint] {
        let columnXPoint = { (column: Int) -> CGFloat in
            return self.barWidth * CGFloat(column)
        }
        
        let columnYPoint = { (graphPoint: CGFloat) -> CGFloat in
            let yPoint = graphPoint / CGFloat(self.maxValue) * size.height
            return size.height - yPoint
        }
        
        var points = [CGPoint]()
        for (index,value) in items.enumerated() {
            points.append(CGPoint(x: columnXPoint(index), y: columnYPoint(value)))
        }
        
        points.insert(CGPoint(x:columnXPoint(0), y: columnYPoint(0)), at: 0)
        points.append(CGPoint(x:columnXPoint(points.count), y: columnYPoint(0)))
        
        return points
    }
    
    private func addGraphPoints(size: CGSize, graphColor: UIColor, borderColor: UIColor?) {
        let context = UIGraphicsGetCurrentContext()
        
        graphColor.setFill()
        if let borderColor = borderColor {
            borderColor.setStroke()
        }
        
        let points = fixPoints(size: size)
        let bezierPath = UIBezierPath(quadCurve: points)
        
        bezierPath?.fill()
        bezierPath?.stroke()
        
        context?.saveGState()
    }
    
    fileprivate func addGraphVerticalBarView(backgroundColor: UIColor?, layer: CALayer?, index: Int, size: CGSize) -> UIView {
        
        let shapeLineView = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height) )
        shapeLineView.accessibilityIdentifier = "GraphVerticalLine\(index)"
        
        if let backgroundColor = backgroundColor {
            shapeLineView.backgroundColor = backgroundColor
        }
        
        shapeLineView.translatesAutoresizingMaskIntoConstraints = false
        
        return shapeLineView
        
    }

    fileprivate func addBorderView(color: UIColor, currentSuperView: UIView, isTrailing: Bool = true) {
        
        let borderView = UIView(frame: CGRect.zero )
        borderView.backgroundColor = color
        
        borderView.translatesAutoresizingMaskIntoConstraints = false
        
        currentSuperView.addSubview(borderView)
        
        
        var horizontalPositionConstraint: NSLayoutConstraint!

        if isTrailing {
            horizontalPositionConstraint = borderView.trailingAnchor.constraint(equalTo: currentSuperView.trailingAnchor, constant: 0)
            borderView.accessibilityIdentifier = "BorderTrailingView"
        } else {
            horizontalPositionConstraint = borderView.leadingAnchor.constraint(equalTo: currentSuperView.leadingAnchor, constant: 0)
            borderView.accessibilityIdentifier = "BorderLeadingView"
        }
        
        NSLayoutConstraint.activate([
            horizontalPositionConstraint,
            borderView.widthAnchor.constraint(equalToConstant: borderWidth),
            borderView.topAnchor.constraint(equalTo: currentSuperView.topAnchor, constant: 0),
            borderView.bottomAnchor.constraint(equalTo: currentSuperView.bottomAnchor, constant: 0)
        ])
    }
    
    private func addGraphVerticalBackgroundBars(size: CGSize, layers: [CALayer?]) {
        
        var previousBarView: UIView?
        
        for (index, layer) in layers.enumerated() {
            let shapeLineView = addGraphVerticalBarView(backgroundColor: nil, layer: layers[index], index: index, size: CGSize(width: barWidth, height: bounds.height))
            
            addSubview(shapeLineView)
            
            
            if let layer = layer {
                layer.needsDisplayOnBoundsChange = true
                layer.frame = shapeLineView.bounds
                shapeLineView.layer.addSublayer(layer)
            }
            
            let leadingConstraint: NSLayoutConstraint!
            if let previousBarView = previousBarView {
                leadingConstraint = shapeLineView.leadingAnchor.constraint(equalTo: previousBarView.trailingAnchor, constant: 0)
            } else {
                leadingConstraint = shapeLineView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
            }
            
            NSLayoutConstraint.activate([
                shapeLineView.widthAnchor.constraint(equalToConstant: barWidth),
                leadingConstraint,
                shapeLineView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
                shapeLineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
            ])
            
            previousBarView = shapeLineView
        }
    }
    
    private func addGraphVerticalLines(size: CGSize, borderColors: [UIColor?], layers: [CALayer?], backgroundColors: [UIColor?]) {
        
        var previousBarView: UIView?
        
        for (index, verticalLineColor) in borderColors.dropFirst().enumerated() {
            guard let verticalLineColor = verticalLineColor else {
                continue
            }
            
            let shapeLineView = addGraphVerticalBarView(backgroundColor: backgroundColors[index], layer: layers[index], index: index, size: CGSize(width: barWidth, height: bounds.height))
            
            addSubview(shapeLineView)
            
            let leadingConstraint: NSLayoutConstraint!
            if let previousBarView = previousBarView {
                leadingConstraint = shapeLineView.leadingAnchor.constraint(equalTo: previousBarView.trailingAnchor, constant: 0)
            } else {
                leadingConstraint = shapeLineView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
            }
            
            NSLayoutConstraint.activate([
                shapeLineView.widthAnchor.constraint(equalToConstant: barWidth),
                leadingConstraint,
                shapeLineView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
                shapeLineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
            ])
            
            if index == 0, let color = borderColors[0] {
                addBorderView(color: color, currentSuperView: shapeLineView, isTrailing: false)
            }
            addBorderView(color: verticalLineColor, currentSuperView: shapeLineView)
            
            previousBarView = shapeLineView
        }
    }
    
    private func addGraphHorizontalLines(size: CGSize, horizontalLines: [(value: CGFloat, color: UIColor)]) {
        for (index, horizontalLine) in horizontalLines.enumerated() {
            
            let yAxis = (size.height - 1.0) * horizontalLine.value

            let shapeLineView = UIView(frame: CGRect.zero )
            shapeLineView.accessibilityIdentifier = "GraphHorizontalLine\(index)"
            
            shapeLineView.backgroundColor = horizontalLine.color
            
            shapeLineView.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(shapeLineView)
            
            shapeLineView.heightAnchor.constraint(equalToConstant: borderWidth).isActive = true
            shapeLineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -yAxis).isActive = true
            shapeLineView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
            shapeLineView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        }
    }
    
    // MARK: - UI Responder Events
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self), let delegate = delegate else {
            return
        }
        isScrolling = false
        let index = Int(location.x / barWidth)
        delegate.graphView?(self, didSelectBarAt: index)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let location = touches.first?.location(in: self), let delegate = delegate else {
            return
        }
        
        if location.x > 0 && location.x < self.frame.width {
            isScrolling = abs(location.x) < abs(location.y)
            let index = Int(location.x / (barWidth - borderWidth))
            delegate.graphView?(self, didSelectBarAt: index)
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        isScrolling = false
    }
    
    // MARK: - Functions
    
    open func item(atIndex index: Int) -> CGFloat {
        return items[index]
    }
}

public extension UIBezierPath {
    
    convenience init?(quadCurve points: [CGPoint]) {
        guard points.count > 1 else { return nil }
        
        self.init()

        var p1 = points[0]
        move(to: p1)
        
        if points.count == 2 {
            addLine(to: points[1])
        }
        
        for i in 0..<points.count {
            let mid = midPoint(p1: p1, p2: points[i])
            
            addQuadCurve(to: mid, controlPoint: controlPoint(p1: mid, p2: p1))
            addQuadCurve(to: points[i], controlPoint: controlPoint(p1: mid, p2: points[i]))
            
            p1 = points[i]
        }
    }
    
    private func midPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
    
    private func controlPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        var controlPoint = midPoint(p1: p1, p2: p2)
        let diffY = abs(p2.y - controlPoint.y)
        
        if p1.y < p2.y {
            controlPoint.y += diffY
        } else if p1.y > p2.y {
            controlPoint.y -= diffY
        }
        return controlPoint
    }
}

#endif
