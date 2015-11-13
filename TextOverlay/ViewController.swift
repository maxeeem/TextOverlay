//
//  ViewController.swift
//  TextOverlay
//
//  Created by Maxim VT on 11/12/15.
//  Copyright © 2015 Maxim VT. All rights reserved.
//

import UIKit

class AutoTextView: UITextView {
  override func layoutSubviews() {
    super.layoutSubviews()
    
    var finalContentSize:CGSize = self.contentSize
    finalContentSize.width  += (self.textContainerInset.left + self.textContainerInset.right ) / 2.0
    finalContentSize.height += (self.textContainerInset.top  + self.textContainerInset.bottom) / 2.0
    
    if finalContentSize.height <= CGRectGetHeight(self.frame) {
      let textViewHeight = (CGRectGetHeight(self.frame) - self.contentSize.height * self.zoomScale)/2.0
      
      self.contentOffset = CGPointMake(0, -(textViewHeight < 0.0 ? 0.0 : textViewHeight))
    }
  }
}



class ViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate {
  var textView: AutoTextView?
  var height: NSLayoutConstraint?
  var width: NSLayoutConstraint?
  var bottom: NSLayoutConstraint?
  var centerX: NSLayoutConstraint?
  var centerY: NSLayoutConstraint?
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
  }
  
  // MARK: Gestures
  
  var tap: UITapGestureRecognizer!
  func tap(sender: UITapGestureRecognizer) {
    if let textView = textView {
      textView.editable = true
      textView.selectable = true
      textView.scrollEnabled = true
      
      center = textView.center
      transform = textView.transform
      
      textView.transform = CGAffineTransformIdentity
      
      textView.becomeFirstResponder()
    }
  }
  
  var pan: UIPanGestureRecognizer!
  func pan(sender: UIPanGestureRecognizer) {
    if let textView = textView {
      if sender.state == .Began || sender.state == .Changed {
        let translation = sender.translationInView(view)
        
        textView.center = CGPointMake(textView.center.x + translation.x, textView.center.y + translation.y)
        
        sender.setTranslation(CGPointZero, inView: view)
      }
    }
  }
  
  @IBOutlet var pinch: UIPinchGestureRecognizer!
  @IBAction func pinch(sender: UIPinchGestureRecognizer) {
    if let textView = textView {
      if sender.numberOfTouches() == 2 {
        let p1 = sender.locationOfTouch(0, inView: view)
        let p2 = sender.locationOfTouch(1, inView: view)
        
        let rect = CGRectStandardize(CGRectMake(p1.x, p1.y,  p2.x - p1.x, p2.y - p1.y))
        
        if rect.intersects(textView.frame) {
          if sender.state == .Began || sender.state == .Changed {
            textView.transform = CGAffineTransformScale(textView.transform, sender.scale, sender.scale)
            sender.scale = 1
          }
        }
      }
    }
  }
  
  @IBOutlet var rotate: UIRotationGestureRecognizer!
  @IBAction func rotate(sender: UIRotationGestureRecognizer) {
    if let textView = textView {
      if sender.numberOfTouches() == 2 {
        let p1 = sender.locationOfTouch(0, inView: view)
        let p2 = sender.locationOfTouch(1, inView: view)
        
        let rect = CGRectStandardize(CGRectMake(p1.x, p1.y,  p2.x - p1.x, p2.y - p1.y))
        
        if rect.intersects(textView.frame) {
          if sender.state == .Began || sender.state == .Changed {
            textView.transform = CGAffineTransformRotate(textView.transform, sender.rotation)
            sender.rotation = 0
          }
        }
      }
    }
  }
  
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  
  // MARK: Toggle Editing Mode ON/OFF
  
  @IBAction func tapOnBackground(sender: UITapGestureRecognizer) {
    guard let textView = textView else {
      createTextView()
      return
    }
    
    if textView.isFirstResponder() {
      textView.resignFirstResponder()
      
      view.removeConstraints([width!, bottom!])
      
      if textView.window != nil {
        centerX = NSLayoutConstraint(item: textView, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: center.x - view.center.x)
        view.addConstraint(centerX!)
        
        centerY = NSLayoutConstraint(item: textView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: center.y - view.center.y)
        view.addConstraint(centerY!)
      }
      
      let aSize = textView.sizeThatFits(self.view.bounds.size)
      
      textView.frame.size = aSize
      
      textView.transform = transform
    }
  }
  
  func createTextView() {
    textView = AutoTextView(frame: CGRectZero)
    textView!.delegate = self
    
    textView!.autocorrectionType = .No
    textView!.spellCheckingType = .No
    
    textView!.font = UIFont.boldSystemFontOfSize(42)
    textView!.textContainer.lineBreakMode = .ByWordWrapping

    textView!.translatesAutoresizingMaskIntoConstraints = false
    
    view.addSubview(textView!)
    
    height = NSLayoutConstraint(item: textView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 75)
    
    textView!.addConstraint(height!)

    textView!.userInteractionEnabled = true
    
    pan = UIPanGestureRecognizer(target: self, action: "pan:")
    textView!.addGestureRecognizer(pan)
    pan.enabled = false
    pan.delegate = self
    
    tap = UITapGestureRecognizer(target: self, action: "tap:")
    textView!.addGestureRecognizer(tap)
    tap.enabled = false
    tap.delegate = self
    
    textView!.editable = true
    textView!.selectable = true
    textView!.scrollEnabled = true
    
    textView!.becomeFirstResponder()
  }
  
  func textViewDidBeginEditing(textView: UITextView) {
    tap.enabled = false
    pan.enabled = false
    pinch.enabled = false
    rotate.enabled = false
  }
  
  func textViewDidEndEditing(textView: UITextView) {
    if textView.text.isEmpty {
      self.textView?.removeFromSuperview()
      self.textView = nil
      
    } else {
      
      tap.enabled = true
      pan.enabled = true
      pinch.enabled = true
      rotate.enabled = true
      
      textView.editable = false
      textView.selectable = false
      textView.scrollEnabled = false
    }
  }
  
  var keyboardFrame = CGRectZero
  var transform = CGAffineTransformIdentity
  lazy var center: CGPoint = { self.view.center }()
  
  func keyboardWillShow(notification: NSNotification) {
    let userInfo = notification.userInfo!
    
    keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
    
    if let textView = textView {
      if let centerX = centerX, centerY = centerY {
        view.removeConstraints([centerX, centerY])
      }
      width = NSLayoutConstraint(item: textView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
      view.addConstraint(width!)
      
      bottom = NSLayoutConstraint(item: textView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: -keyboardFrame.size.height)
      view.addConstraint(bottom!)
    }
  }

  
  // MARK: TextView Height Adjust
  
  lazy var maxHeight: CGFloat = { return self.view.bounds.height }()
  
  func textViewDidChange(textView: UITextView) {
    var finalContentSize:CGSize = textView.contentSize
    finalContentSize.width  += (textView.textContainerInset.left + textView.textContainerInset.right ) / 2.0
    finalContentSize.height += (textView.textContainerInset.top  + textView.textContainerInset.bottom) / 2.0
    
    var customContentSize = finalContentSize
    
    customContentSize.height = min(customContentSize.height, CGFloat(maxHeight))
    
    self.height?.constant = customContentSize.height
  }

}

