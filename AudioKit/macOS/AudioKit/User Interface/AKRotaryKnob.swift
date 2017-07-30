//
//  AKBypassButton.swift
//  AudioKit for macOS
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2017 Aurelius Prochazka. All rights reserved.
//


public enum AKRotaryKnobStyle {
    case round
    case polygon(numberOfSides: Int, curvature: Double)
}


@IBDesignable open class AKRotaryKnob: AKView {
    
    // Default side
    static var defaultSize = CGSize(width: 150.0, height: 170.0)
    
    // Default margin size
    static var marginSize: CGFloat = 30.0
    
    // Indicator point radius
    static var indicatorPointRadius: CGFloat = 3.0
    
    // Padding surrounding the text inside the value bubble
    static var bubblePadding: CGSize = CGSize(width: 10.0, height: 2.0)
    
    // Margin between the top of the tap and the value bubble
    static var bubbleMargin: CGFloat = 3.0
    
    // Corner radius for the value bubble
    static var bubbleCornerRadius: CGFloat = 2.0
    
    // Maximum curvature value for polygon style knob
    static var maximumPolygonCurvature = 1.0
    
    /// Current value of the slider
    @IBInspectable open var value: Double = 0 {
        didSet {
            needsDisplay = true
        }
    }
    
    /// Minimum, left-most value
    @IBInspectable open var minimum: Double = 0
    
    /// Maximum, right-most value
    @IBInspectable open var maximum: Double = 1
    
    // Should the knob uses discrete values
    @IBInspectable open var usesDiscreteValues: Bool = false
    
    // The step for each discrete value
    @IBInspectable open var discreteValueStep: Double = 0.1
    
    /// Text shown on the knob
    @IBInspectable open var property: String = "Property"
    
    /// Format for the number shown on the knob
    @IBInspectable open var format: String = "%0.3f"
    
    /// Background color
    @IBInspectable open var bgColor: AKColor?
    
    /// Knob border color
    @IBInspectable open var knobBorderColor: AKColor?
    
    /// Knob indicator color
    @IBInspectable open var indicatorColor: AKColor?
    
    /// Knob overlay color
    @IBInspectable open var knobColor: AKColor = AKStylist.sharedInstance.nextColor
    
    /// Text color
    @IBInspectable open var textColor: AKColor?
    
    /// Font size
    @IBInspectable open var fontSize: CGFloat = 20
    
    /// Bubble font size
    @IBInspectable open var bubbleFontSize: CGFloat = 12
    
    // Slider style. Curvature is a value between -1.0 and 1.0, where 0.0 indicates no curves
    open var knobStyle: AKRotaryKnobStyle = AKRotaryKnobStyle.polygon(numberOfSides: 9, curvature: 0.0)
    
    // Border width
    @IBInspectable open var knobBorderWidth: CGFloat = 8.0
    
    // Value bubble border width
    @IBInspectable open var valueBubbleBorderWidth: CGFloat = 1.0
    
    // Number of indicator points
    @IBInspectable open var numberOfIndicatorPoints = 11
    
    // Current dragging state, used to show/hide the value bubble
    private var isDragging: Bool = false
    
    // Calculate knob center
    private var knobCenter: CGPoint = CGPoint.zero
    
    /// Function to call when value changes
    open var callback: ((Double) -> Void)?
    fileprivate var lastTouch = CGPoint.zero
    
    /// Initialize the slider
    public init(property: String,
                format: String = "%0.3f",
                value: Double,
                minimum: Double = 0,
                maximum: Double = 1,
                color: AKColor = AKColor.red,
                frame: CGRect = CGRect(x: 0, y: 0, width: AKRotaryKnob.defaultSize.width, height: AKRotaryKnob.defaultSize.height),
                callback: @escaping (_ x: Double) -> Void) {
        self.value = value
        self.minimum = minimum
        self.maximum = maximum
        self.property = property
        self.format = format
        self.knobColor = color
        
        self.callback = callback
        super.init(frame: frame)
        
        self.wantsLayer = true
        
        needsDisplay = true
    }
    
    /// Initialization with no details
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        self.wantsLayer = true
    }
    
    /// Initialization within Interface Builder
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.wantsLayer = true
    }
    
    /// Actions to perform to make sure the view is renderable in Interface Builder
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()

        self.wantsLayer = true
    }
    
    
    /// Give the slider a random value
    open func randomize() -> Double {
        value = random(minimum, maximum)
        needsDisplay = true
        return value
    }
    
    func angleBetween(pointA: CGPoint, pointB: CGPoint) -> Double {
        let dx = Double(pointB.x - pointA.x)
        let dy = Double(pointB.y - pointA.y)
        let radians = atan2(-dx, -dy)
        let degrees = radians * 180 / Double.pi
        return degrees
    }
    
    override open func mouseDown(with theEvent: NSEvent) {
        isDragging = true
        let loc = convert(theEvent.locationInWindow, from: nil)
        lastTouch = loc
        let angle = angleBetween(pointA: knobCenter, pointB: loc)
        if angle < 0.0 {
            value = (maximum - minimum) * (0.5 + 0.5 * (180.0 + angle) / (105.0))
        } else {
            value = (maximum - minimum) * ((angle - 75.0) / 110.0) * 0.5
        }
        if usesDiscreteValues && discreteValueStep > 0.0 {
            let step = Int(value / discreteValueStep)
            let lowerValue = step * discreteValueStep
            let higherValue = (step + 1) * (discreteValueStep)
            value = abs(value - lowerValue) < abs(higherValue - value) ? lowerValue : higherValue
        }
        if value > maximum { value = maximum }
        if value < minimum { value = minimum }
        needsDisplay = true
        callback?(value)
    }
    
    override open func mouseDragged(with theEvent: NSEvent) {
        let loc = convert(theEvent.locationInWindow, from: nil)
        lastTouch = loc
        let angle = angleBetween(pointA: knobCenter, pointB: loc)
        if angle < 0.0 {
            value = (maximum - minimum) * (0.5 + 0.5 * (180.0 + angle) / (105.0))
        } else {
            value = (maximum - minimum) * ((angle - 75.0) / 110.0) * 0.5
        }
        if usesDiscreteValues && discreteValueStep > 0.0 {
            let step = Int(value / discreteValueStep)
            let lowerValue = step * discreteValueStep
            let higherValue = (step + 1) * (discreteValueStep)
            value = abs(value - lowerValue) < abs(higherValue - value) ? lowerValue : higherValue
        }
        if value > maximum { value = maximum }
        if value < minimum { value = minimum }
        needsDisplay = true
        callback?(value)
    }
    
    open override func mouseUp(with theEvent: NSEvent) {
        isDragging = false
        needsDisplay = true
    }
    
    open func indicatorColorForTheme() -> AKColor {
        if let indicatorColor = indicatorColor { return indicatorColor }
        
        switch AKStylist.sharedInstance.theme {
        case .basic: return AKColor(white: 0.3, alpha: 1.0)
        case .midnight: return AKColor.white
        }
    }
    
    open func knobBorderColorForTheme() -> AKColor {
        if let knobBorderColor = knobBorderColor { return knobBorderColor }
        
        switch AKStylist.sharedInstance.theme {
        case .basic: return AKColor(white: 0.2, alpha: 1.0)
        case .midnight: return AKColor(white: 1.0, alpha: 1.0)
        }
    }
    
    open func textColorForTheme() -> AKColor {
        if let textColor = textColor { return textColor }
        
        switch AKStylist.sharedInstance.theme {
        case .basic: return AKColor(white: 0.3, alpha: 1.0)
        case .midnight: return AKColor.white
        }
    }
    
    override open func draw(_ rect: NSRect) {
        drawKnob(currentValue: CGFloat(value),
                 minimum: minimum,
                 maximum: maximum,
                 propertyName: property,
                 currentValueText: String(format: format, value))
    }
    
    func drawKnob(currentValue: CGFloat = 0,
                  initialValue: CGFloat = 0,
                  minimum: Double = 0,
                  maximum: Double = 1,
                  propertyName: String = "Property Name",
                  currentValueText: String = "0.0") {
        
        //// General Declarations
        let context = unsafeBitCast(NSGraphicsContext.current()?.graphicsPort, to: CGContext.self)
        
        let width = self.frame.width
        let height = self.frame.height
        
        let nameLabelRect = CGRect(x: 0, y: 0, width: width, height: height)
        let nameLabelStyle = NSMutableParagraphStyle()
        nameLabelStyle.alignment = .center
        
        let textColor = textColorForTheme()
        
        let nameLabelFontAttributes = [NSFontAttributeName: NSFont.boldSystemFont(ofSize: fontSize),
                                       NSForegroundColorAttributeName: textColor,
                                       NSParagraphStyleAttributeName: nameLabelStyle] as [String : Any]
        
        let nameLabelTextHeight: CGFloat = NSString(string: propertyName).boundingRect(
            with: CGSize(width: width, height: CGFloat.infinity),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: nameLabelFontAttributes,
            context: nil).size.height
        context.saveGState()
        
        // Draw name label
        let nameLabelInset: CGRect = nameLabelRect.insetBy(dx: 0.0, dy: 0)
        context.clip(to: nameLabelInset)
        NSString(string: propertyName).draw(
            in: CGRect(x: nameLabelInset.minX,
                       y: nameLabelInset.minY,
                       width: nameLabelInset.width,
                       height: nameLabelTextHeight),
            withAttributes: nameLabelFontAttributes)
        context.restoreGState()
        
        // Calculate knob size
        let knobDiameter = min(width, height) - AKRotaryKnob.marginSize * 2.0
        knobCenter = CGPoint(x: AKRotaryKnob.marginSize + knobDiameter / 2.0, y: AKRotaryKnob.marginSize + knobDiameter / 2.0)
        
        // Setup indicator
        let valuePercent = (value - minimum) / (maximum - minimum)
        let angle = Double.pi * ( 0.75 + valuePercent * 1.5)
        let indicatorStart = CGPoint(x: (knobDiameter / 5.0) * CGFloat(cos(angle)), y: nameLabelTextHeight - (knobDiameter / 5.0) * CGFloat(sin(angle)))
        let indicatorEnd = CGPoint(x: (knobDiameter / 2.0) * CGFloat(cos(angle)), y: nameLabelTextHeight - (knobDiameter / 2.0) * CGFloat(sin(angle)))
        
        // Draw knob
        let knobRect = CGRect(x: AKRotaryKnob.marginSize, y: nameLabelTextHeight + AKRotaryKnob.marginSize, width: knobDiameter, height: knobDiameter)
        let knobPath: NSBezierPath = {
            switch self.knobStyle {
            case .round:
                return NSBezierPath(roundedRect: knobRect, xRadius: knobDiameter / 2.0, yRadius: knobDiameter / 2.0)
            case .polygon (let numberOfSides, let curvature):
                return bezierPathWithPolygonInRect(knobRect, numberOfSides: numberOfSides, curvature: curvature, startPoint: CGPoint(x: AKRotaryKnob.marginSize + knobDiameter / 2.0 + indicatorEnd.x, y: AKRotaryKnob.marginSize + knobDiameter / 2.0 + indicatorEnd.y), offsetAngle: angle)
            }
        }()
        
        knobPath.lineWidth = knobBorderWidth
        knobBorderColorForTheme().setStroke()
        knobPath.stroke()
        knobColor.setFill()
        knobPath.fill()
        
        // Draw indicator
        let indicatorPath = NSBezierPath()
        indicatorPath.move(to: CGPoint(x: AKRotaryKnob.marginSize + knobDiameter / 2.0 + indicatorStart.x, y: AKRotaryKnob.marginSize + knobDiameter / 2.0 + indicatorStart.y))
        indicatorPath.line(to: NSPoint(x: AKRotaryKnob.marginSize + knobDiameter / 2.0 + indicatorEnd.x, y: AKRotaryKnob.marginSize + knobDiameter / 2.0 + indicatorEnd.y))
        indicatorPath.lineWidth = knobBorderWidth / 2.0
        indicatorColorForTheme().setStroke()
        indicatorPath.stroke()
        
        // Draw points
        let pointRadius = (knobDiameter / 2.0) + AKRotaryKnob.marginSize * 0.6
        for i in 0...numberOfIndicatorPoints - 1 {
            let pointPercent = Double(i) / Double(numberOfIndicatorPoints - 1)
            let pointAngle = Double.pi * ( 0.75 + pointPercent * 1.5)
            let pointX = AKRotaryKnob.marginSize + knobDiameter / 2.0 + (pointRadius) * CGFloat(cos(pointAngle)) - AKRotaryKnob.indicatorPointRadius
            let pointY = AKRotaryKnob.marginSize + knobDiameter / 2.0 - (pointRadius) * CGFloat(sin(pointAngle)) - AKRotaryKnob.indicatorPointRadius + nameLabelTextHeight
            let pointRect = CGRect(x: pointX, y: pointY, width: AKRotaryKnob.indicatorPointRadius * 2.0, height: AKRotaryKnob.indicatorPointRadius * 2.0)
            let pointPath = NSBezierPath(roundedRect: pointRect, xRadius: AKRotaryKnob.indicatorPointRadius, yRadius: AKRotaryKnob.indicatorPointRadius)
            if valuePercent > 0.0 && pointPercent <= valuePercent {
                knobColor.setFill()
            } else {
                knobColor.withAlphaComponent(0.2).setFill()
            }
            pointPath.fill()
        }
        
        //// valueLabel Drawing
        if isDragging {
            let valueLabelRect = CGRect(x: 0, y: 0, width: width, height: height)
            let valueLabelStyle = NSMutableParagraphStyle()
            valueLabelStyle.alignment = .center
            
            let valueLabelFontAttributes = [NSFontAttributeName: NSFont.boldSystemFont(ofSize: bubbleFontSize),
                                            NSForegroundColorAttributeName: textColor,
                                            NSParagraphStyleAttributeName: valueLabelStyle] as [String : Any]
            
            let valueLabelInset: CGRect = valueLabelRect.insetBy(dx: 0, dy: 0)
            let valueLabelTextSize = NSString(string: currentValueText).boundingRect(
                with: CGSize(width: valueLabelInset.width, height: CGFloat.infinity),
                options: NSStringDrawingOptions.usesLineFragmentOrigin,
                attributes: valueLabelFontAttributes,
                context: nil).size
            
            let bubbleSize = CGSize(width: valueLabelTextSize.width + AKRotaryKnob.bubblePadding.width, height: valueLabelTextSize.height + AKRotaryKnob.bubblePadding.height)
            
            var bubbleOriginX = (lastTouch.x - bubbleSize.width / 2.0 - valueBubbleBorderWidth)
            if bubbleOriginX < 0.0 {
                bubbleOriginX = valueBubbleBorderWidth
            } else if (bubbleOriginX + bubbleSize.width) > bounds.width {
                bubbleOriginX = bounds.width - bubbleSize.width - valueBubbleBorderWidth
            }
            
            var bubbleOriginY = (lastTouch.y + bubbleSize.height/2.0 + valueBubbleBorderWidth)
            if bubbleOriginY > height - bubbleSize.height {
                bubbleOriginY = height - bubbleSize.height
            } else if bubbleOriginY < 0.0 {
                bubbleOriginY = 0.0
            }
            
            let bubbleRect = CGRect(x: bubbleOriginX,
                                    y: bubbleOriginY,
                                    width: bubbleSize.width,
                                    height: bubbleSize.height)
            let bubblePath = NSBezierPath(roundedRect: bubbleRect, xRadius: AKRotaryKnob.bubbleCornerRadius, yRadius: AKRotaryKnob.bubbleCornerRadius)
            knobColor.setFill()
            bubblePath.fill()
            bubblePath.lineWidth = valueBubbleBorderWidth
            knobBorderColorForTheme().setStroke()
            bubblePath.stroke()
            
            context.saveGState()
            context.clip(to: valueLabelInset)
            NSString(string: currentValueText).draw(
                in: CGRect(x: bubbleOriginX + ((bubbleSize.width - valueLabelTextSize.width) / 2.0),
                           y: bubbleOriginY + AKRotaryKnob.bubblePadding.height/2.0,
                           width: valueLabelTextSize.width,
                           height: valueLabelTextSize.height),
                withAttributes: valueLabelFontAttributes)
            context.restoreGState()
        }
    }
    
    func bezierPathWithPolygonInRect(_ rect: CGRect, numberOfSides: Int, curvature: Double, startPoint: CGPoint, offsetAngle: Double) -> NSBezierPath {
        guard numberOfSides > 2 else {
            return NSBezierPath(rect: rect)
        }
        
        let path = NSBezierPath()
        path.move(to: startPoint)
        for i in 0...numberOfSides {
            let angle = 2 * Double.pi * i / numberOfSides + offsetAngle
            let nextX = rect.midX + rect.width / 2.0 * CGFloat(cos(angle))
            let nextY = rect.midY - rect.height / 2.0 * CGFloat(sin(angle))
            if curvature == 0.0 {
                path.line(to: NSPoint(x: nextX, y: nextY))
            } else {
                var actualCurvature = curvature
                if (curvature > AKRotaryKnob.maximumPolygonCurvature) {
                    actualCurvature = AKRotaryKnob.maximumPolygonCurvature
                }
                if (curvature < AKRotaryKnob.maximumPolygonCurvature * -1.0) {
                    actualCurvature = AKRotaryKnob.maximumPolygonCurvature * -1.0
                }
                let arcAngle = 2 * Double.pi * (i - 0.5) / numberOfSides + offsetAngle
                let arcX = rect.midX + (rect.width * CGFloat(1.0 + actualCurvature*0.25)) / 2.0 * CGFloat(cos(arcAngle))
                let arcY = rect.midY - (rect.height * CGFloat(1.0 + actualCurvature*0.25)) / 2.0 * CGFloat(sin(arcAngle))
                path.curve(to: NSPoint(x: nextX, y: nextY), controlPoint1: NSPoint(x: arcX, y: arcY), controlPoint2: NSPoint(x: arcX, y: arcY))
            }
        }
        path.close()
        return path
    }
}
