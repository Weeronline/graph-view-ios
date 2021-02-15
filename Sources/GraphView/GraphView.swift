#if canImport(UIKit)
import UIKit

public class GraphView: UIView {
    
    var isScrolling = false
    var barWidth: CGFloat = 20
    
    private var temporalNumberOfItems = 10
    private var temportalColorForVerticalLine: UIColor? = UIColor.red
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
          return
        }
                
        addGraphVerticalLines(size: rect.size)
       
        context.saveGState()
    }
    
    // MARK: - Drawing
    
    private func addGraphVerticalLines(size: CGSize) {
        for index in 0...temporalNumberOfItems {
            guard let verticalLineColor = temportalColorForVerticalLine else {
                continue
            }

            let linePath = UIBezierPath()
            
            let xAxis = barWidth * CGFloat(index)
            linePath.move(to: CGPoint(x: xAxis, y: 0))
            linePath.addLine(to: CGPoint(x: xAxis, y: size.height))
            
            verticalLineColor.setStroke()
            linePath.lineWidth = 1.0
            linePath.stroke()
        }
    }
    
}

#endif
