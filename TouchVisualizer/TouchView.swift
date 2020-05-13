//
//  TouchView.swift
//  TouchVisualizer
//

import UIKit

final public class TouchView: UIImageView {
    
    // MARK: - Public Variables
    internal weak var touch: UITouch?
    private weak var timer: Timer?
    private var _config: Configuration
    private var previousRatio: CGFloat = 1.0
    private var startDate: Date?
    private var lastTimeString: String!
    
    public var config: Configuration {
        get { return _config }
        set (value) {
            _config = value
            timerLabel.textColor = self.config.color
            backgroundColor = .clear
        }
    }
    
    lazy var timerLabel: UILabel = {
        let size = CGSize(width: 200.0, height: 44.0)
        let bottom: CGFloat = 8.0
        var label = UILabel()
        
        label.frame = CGRect(x: -(size.width - self.frame.width) / 2,
                             y: -size.height - bottom,
                             width: size.width,
                             height: size.height)
        
        label.font = UIFont(name: "Helvetica", size: 24.0)
        label.textAlignment = .center
        self.addSubview(label)
        
        return label
    }()
    
    @available(iOS 13.0, *)
    private var blur: UIBlurEffect.Style {
      .light
    }
    
    lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: blur)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }()
    
    private let redCircle: CAShapeLayer = {
        let redCircle = CAShapeLayer()
        redCircle.shadowColor = UIColor.black.cgColor
        redCircle.shadowOffset = .zero
        redCircle.shadowRadius = 3
        redCircle.shadowOpacity = 0.5
        redCircle.fillColor = UIColor(white: 1, alpha: 0.1).cgColor
        return redCircle
    }()
    
    
    // MARK: - Object life cycle
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        _config = Configuration()
        super.init(frame: frame)
        self.addSubview(blurView)
        self.layer.addSublayer(redCircle)

        self.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: _config.defaultSize)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame = self.bounds
        blurView.layer.masksToBounds = true
        blurView.layer.cornerRadius = bounds.width/2
        
        redCircle.path = UIBezierPath(ovalIn: bounds).cgPath
        redCircle.position = CGPoint(x: 0, y: 0)


        let mask = CAShapeLayer()
        let diameter = bounds.width
        let extraLineWidth: CGFloat = 6
        let rect = CGRect(x: -extraLineWidth / 2, y: -extraLineWidth / 2, width: diameter, height: diameter)

        mask.path = UIBezierPath(ovalIn: rect).cgPath
        mask.fillColor = UIColor.clear.cgColor
        mask.strokeColor = UIColor.white.cgColor
        mask.lineWidth = 6
        mask.position = CGPoint(x: extraLineWidth / 2, y: extraLineWidth / 2)
        redCircle.mask = mask
        
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Begin and end touching functions
    internal func beginTouch() {
        alpha = 1.0
        timerLabel.alpha = 0.0
        layer.transform = CATransform3DIdentity
        previousRatio = 1.0
        frame = CGRect(origin: frame.origin, size: _config.defaultSize)
        startDate = Date()
        timer = Timer.scheduledTimer(timeInterval: 1.0 / 60.0, target: self, selector: #selector(self.update(_:)), userInfo: nil, repeats: true)
        
        RunLoop
            .main
            .add(timer!, forMode: RunLoop.Mode.common)
        
        if _config.showsTimer {
            timerLabel.alpha = 1.0
        }
        
        if _config.showsTouchRadius {
            updateSize()
        }
    }
    
    func endTouch() {
        timer?.invalidate()
    }
    
    // MARK: - Update Functions
    @objc internal func update(_ timer: Timer) {
        guard let startDate = startDate else { return }
        
        let interval = Date().timeIntervalSince(startDate)
        let timeString = String(format: "%.02f", Float(interval))
        timerLabel.text = timeString
        
        if _config.showsTouchRadius {
            updateSize()
        }
    }
    
    internal func updateSize() {
        guard let touch = touch else { return }
        let ratio = touch.majorRadius * 2.0 / _config.defaultSize.width
        if ratio != previousRatio {
            layer.transform = CATransform3DMakeScale(ratio, ratio, 1.0)
            previousRatio = ratio
        }
    }
}
