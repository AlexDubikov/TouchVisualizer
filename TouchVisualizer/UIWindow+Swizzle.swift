//
//  UIWindow+Swizzle.swift
//  TouchVisualizer
//

import UIKit

public class WindowWithEvents: UIWindow {
    public unowned var visualizer: Visualizer?
    
    public override func sendEvent(_ event: UIEvent) {
        visualizer?.handleEvent(event)
        super.sendEvent(event)
    }
}
