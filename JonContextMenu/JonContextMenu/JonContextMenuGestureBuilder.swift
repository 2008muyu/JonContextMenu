//
//  JonContextMenuGestureBuilder.swift
//  JonContextMenu
//
//  Created by mby on 2020/3/26.
//  Copyright © 2020 Surrey. All rights reserved.
//

import Foundation

extension JonContextMenu {
    
    @objc open func buildTapGesture()->BuilderTapGesture{
        return BuilderTapGesture(self)
    }
    
}


@objc open class BuilderTapGesture:UITapGestureRecognizer{
    
    /// The wrapper for the JonContextMenu
    private var window:UIWindow!
    
    /// The selected menu item
    private var currentItem:JonItem?
    
    /// The JonContextMenu view
    private var contextMenuView:JonContextMenuView!
    
    /// The properties configuration to add to the JonContextMenu view
    private var properties:JonContextMenu!
    
    /// Indicates if there is a menu item active
    private var isItemActive = false
    
    @objc  init(_ properties:JonContextMenu){
        super.init(target: nil, action: nil)
        guard let window = UIApplication.shared.keyWindow else{
            fatalError("No access to UIApplication Window")
        }
        self.window     = window
        self.properties = properties
        
        for item in self.properties.items {
            item.onClickAction = {[weak self] (id) in
                self?.onItemClick(id: id)
            }
        }
        
    }
    
    func onItemClick(id : NSInteger) -> Void {
        self.properties.items.forEach { (item) in
            if let idd = item.id {
                if idd == id {
                    currentItem = item
                }
            }
        }
        
        if let currentItem = currentItem{
            if !currentItem.isActive{
                contextMenuView.activate(currentItem, completed: {[weak self](finished) in
                    self?.properties.delegate?.menuItemWasActivated(item: currentItem)
                    self?.dismissMenu()
                })
            }else {
                contextMenuView.deactivate(currentItem)
                properties.delegate?.menuItemWasDeactivated(item: currentItem)
            }
        }
    }
    
    /// Gets a copy of the touched view to add to the Window
    private func getTouchedView(){
        let highlightedView   = self.view!.snapshotView(afterScreenUpdates: true)!
        highlightedView.frame = self.view!.superview!.convert(self.view!.frame, to: nil)
        highlightedView.borderWidth = 0.5
        highlightedView.borderColor = .lightGray
        properties.highlightedView = highlightedView
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first {
            let location = touch.location(in: window)
            getTouchedView()
            showMenu(on: location)
        }
    }
    
    /// Creates the JonContextMenu view and adds to the Window
    private func showMenu(on location:CGPoint){
        currentItem     = nil
        contextMenuView = JonContextMenuView(properties, touchPoint: location, isTap: true)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(contextMenuViewTapAction))
        contextMenuView.background.addGestureRecognizer(tap)
        
        window.addSubview(contextMenuView)
        properties.delegate?.menuOpened()
    }
    
    /// Removes the JonContextMenu view from the Window
    @objc private func dismissMenu(){
        if let currentItem = currentItem{
            contextMenuView.deactivate(currentItem)
        }

        contextMenuView.removeFromSuperview()
        properties.delegate?.menuClosed()
        contextMenuView = nil
    }
    
    @objc private func contextMenuViewTapAction (gesture : UITapGestureRecognizer) {
        self.dismissMenu()
    }
}
