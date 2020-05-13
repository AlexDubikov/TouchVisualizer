//
//  TouchVisualizer.swift
//  TouchVisualizer
//

import UIKit

final public class Visualizer:NSObject {
    
    // MARK: - Public Variables
    private var enabled = false
    private var config: Configuration!
    private var touchViews = [TouchView]()
    private var previousLog = ""
    unowned let window: UIWindow
    
    // MARK: - Object life cycle
    public init(window: UIWindow) {
        self.window = window
        super.init()
        NotificationCenter
            .default
            .addObserver(self, selector: #selector(Visualizer.orientationDidChangeNotification(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        UIDevice
            .current
            .beginGeneratingDeviceOrientationNotifications()
        
        warnIfSimulator()
    }
    
    deinit {
        NotificationCenter
            .default
            .removeObserver(self)
    }
    
    @objc internal func orientationDidChangeNotification(_ notification: Notification) {
        for touch in touchViews {
            touch.removeFromSuperview()
        }
    }
    
    public func removeAllTouchViews() {
        for view in self.touchViews {
            view.removeFromSuperview()
        }
    }
}

extension Visualizer {
    public func isEnabled() -> Bool {
        return self.enabled
    }
    
    // MARK: - Start and Stop functions
    
    public func start(_ config: Configuration = Configuration()) {
		
        self.config = config
        
		if config.showsLog {
			print("Visualizer start...")
		}
        enabled = true
        
        for subview in window.subviews {
            if let subview = subview as? TouchView {
                subview.removeFromSuperview()
            }
        }
		if config.showsLog {
			print("started !")
		}
    }
    
    public func stop() {
        enabled = false
        
        for touch in touchViews {
            touch.removeFromSuperview()
        }
    }
    
    public func getTouches() -> [UITouch] {
        var touches: [UITouch] = []
        for view in touchViews {
            guard let touch = view.touch else { continue }
            touches.append(touch)
        }
        return touches
    }
    
    // MARK: - Dequeue and locating TouchViews and handling events
    private func dequeueTouchView() -> TouchView {
        var touchView: TouchView?
        for view in touchViews {
            if view.superview == nil {
                touchView = view
                break
            }
        }
        
        if touchView == nil {
            touchView = TouchView()
            touchViews.append(touchView!)
        }
        
        return touchView!
    }
    
    private func findTouchView(_ touch: UITouch) -> TouchView? {
        for view in touchViews {
            if touch == view.touch {
                return view
            }
        }
        
        return nil
    }
    
    public func handleEvent(_ event: UIEvent) {
        if event.type != .touches {
            return
        }
        
        if !enabled {
            return
        }

        
        for touch in event.allTouches! {
            let phase = touch.phase
            switch phase {
            case .began:
                let view = dequeueTouchView()
                view.config = config
                view.touch = touch
                view.beginTouch()
                view.center = touch.location(in: window)
                window.addSubview(view)
                log(touch)
            case .moved:
                if let view = findTouchView(touch) {
                    view.center = touch.location(in: window)
                }
                
                log(touch)
            case .stationary:
                log(touch)
            case .ended, .cancelled:
                if let view = findTouchView(touch) {
                    UIView.animate(withDuration: 0.2, delay: 0.0, options: .allowUserInteraction, animations: { () -> Void  in
                        view.alpha = 0.0
                        view.endTouch()
                    }, completion: { [unowned self] (finished) -> Void in
                        view.removeFromSuperview()
                        self.log(touch)
                    })
                }
                
                log(touch)
            case .regionEntered:
                log(touch)
            case .regionMoved:
                log(touch)
            case .regionExited:
                log(touch)
            @unknown default:
                log(touch)
            }
        }
    }
}

extension Visualizer {
    public func warnIfSimulator() {
        #if targetEnvironment(simulator)
            print("[TouchVisualizer] Warning: TouchRadius doesn't work on the simulator because it is not possible to read touch radius on it.", terminator: "")
        #endif
    }
    
    // MARK: - Logging
    public func log(_ touch: UITouch) {
        if !config.showsLog {
            return
        }
        
        var ti = 0
        var viewLogs = [[String:String]]()
        for view in touchViews {
            var index = ""
            
            index = "\(ti)"
            ti += 1
            
            var phase: String!
            switch touch.phase {
            case .began: phase = "B"
            case .moved: phase = "M"
            case .stationary: phase = "S"
            case .ended: phase = "E"
            case .cancelled: phase = "C"
            case .regionEntered:
                phase = "N"
            case .regionMoved:
                phase = "V"
            case .regionExited:
                phase =  "X"
            @unknown default:
                phase = "Z"
            }
            
            let x = String(format: "%.02f", view.center.x)
            let y = String(format: "%.02f", view.center.y)
            let center = "(\(x), \(y))"
            let radius = String(format: "%.02f", touch.majorRadius)
            viewLogs.append(["index": index, "center": center, "phase": phase, "radius": radius])
        }
        
        var log = ""
        
        for viewLog in viewLogs {
            
            if (viewLog["index"]!).count == 0 {
                continue
            }
            
            let index = viewLog["index"]!
            let center = viewLog["center"]!
            let phase = viewLog["phase"]!
            let radius = viewLog["radius"]!
            log += "Touch: [\(index)]<\(phase)> c:\(center) r:\(radius)\t\n"
        }
        
        if log == previousLog {
            return
        }
        
        previousLog = log
        print(log, terminator: "")
    }
}
