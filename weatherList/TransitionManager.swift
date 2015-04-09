//
//  TransitionManager.swift
//  weatherList
//
//  Created by Chris Budro on 4/1/15.
//  Copyright (c) 2015 chrisbudro. All rights reserved.
//

import UIKit
import QuartzCore

class TransitionManager: UIPercentDrivenInteractiveTransition, UIViewControllerInteractiveTransitioning, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    private var presenting : Bool = false
    private var interactive : Bool = false
    private var dismissPanGesture : UIPanGestureRecognizer!
     
    var locationsListController : LocationsTableViewController!

    
    //MARK: Animator
   
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView()
        
        let screens : (from:UIViewController, to: UIViewController) = (
                        transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!,
                        transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!)
        
        let locationsListController = !self.presenting ? screens.from as! LocationsTableViewController : screens.to as! LocationsTableViewController
        let weatherViewController = !self.presenting ? screens.to as! WeatherViewController : screens.from as! WeatherViewController
        
        let locationsView = locationsListController.view
        let weatherView = weatherViewController.view
        
        container.addSubview(locationsView)
        container.addSubview(weatherView)
    
        let duration = self.transitionDuration(transitionContext)
        
        if (self.presenting) {
//            self.swipeListOffFrame(locationsListController)
            self.swipeInList(locationsListController)
            weatherView.layer.shadowColor = UIColor.blackColor().CGColor
            weatherView.layer.shadowOffset = CGSizeMake(2.0, 2.0)
            weatherView.layer.shadowOpacity = 0.8
            weatherView.layer.shadowRadius = 15.0

        }
        
        UIView.animateWithDuration(duration, delay: 0,  options: nil, animations: {
            
                if (self.presenting) {
                    self.swipeMainOffFrame(weatherViewController)
                    self.swipeInList(locationsListController)


                } else {
                    self.returnToFrame(weatherViewController)
//                    self.returnList(locationsListController)
                }
            
            }, completion: { finished in
                
                if (transitionContext.transitionWasCancelled()) {
                    transitionContext.completeTransition(false)

                } else {
                    transitionContext.completeTransition(true)
                    UIApplication.sharedApplication().keyWindow?.addSubview(screens.to.view)
                    
                    if (self.presenting) {
                        UIApplication.sharedApplication().keyWindow?.addSubview(screens.from.view)
                        self.addTapGesture(weatherViewController)
                        self.changeButtonControl(weatherViewController, presenting: true)
                        weatherViewController.collectionView?.scrollEnabled = false
                        self.setPanGesture(weatherViewController)
                        
                    } else {
                        self.changeButtonControl(weatherViewController, presenting: false)
                        weatherViewController.view.removeGestureRecognizer(self.dismissPanGesture)
                         weatherViewController.collectionView?.scrollEnabled = true
                    }
                }
                
            })
        }
    
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.4
    }
    
    
    //MARK: Interaction Delegate
    
    func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.interactive ? self : nil
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.interactive ? self : nil
    }
    
    //MARK: Helper Methods
    
    func changeButtonControl(weatherViewController: WeatherViewController, presenting: Bool) {

        weatherViewController.addLocationsButton.target = nil
        
        if (presenting) {
            weatherViewController.addLocationsButton.target = self
            weatherViewController.addLocationsButton.action = "handleButtonPress"

        } else {
            weatherViewController.addLocationsButton.target = weatherViewController
            weatherViewController.addLocationsButton.action = "addWasPressed:"
        }
    }
    
    func addTapGesture(weatherViewController: WeatherViewController) {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: "handleTapGesture:")
        weatherViewController.view.addGestureRecognizer(tapGesture)
        
    }
    
    func setPanGesture(weatherViewController: WeatherViewController) {
        self.dismissPanGesture = UIPanGestureRecognizer()
        self.dismissPanGesture.addTarget(self, action: "handleDismissPan:")
        weatherViewController.view.addGestureRecognizer(self.dismissPanGesture)
    }
    
    func swipeMainOffFrame(weatherViewController: WeatherViewController) {
        weatherViewController.view.transform = offFrame(-weatherViewController.view.frame.width + 50)
        
    }
    
    func returnToFrame(weatherViewController: WeatherViewController) {
        weatherViewController.view.transform = CGAffineTransformIdentity
        
    }
    
    func swipeListOffFrame(locationsListController: LocationsTableViewController) {
        locationsListController.view.transform = offFrame(-150)
    }
    
    func swipeInList(locationsListController : LocationsTableViewController) {
        locationsListController.view.transform = offFrame(50)
        
    }
    
    func returnList(locationsListController: LocationsTableViewController) {
        locationsListController.view.transform = CGAffineTransformIdentity
    }
    
    
    func offFrame(amount: CGFloat) -> CGAffineTransform {
        return CGAffineTransformMakeTranslation(amount, 0)
    }
    
    
    func handleDismissPan(pan: UIPanGestureRecognizer) {
        let translation = pan.translationInView(pan.view!)
        let d = translation.x / CGRectGetWidth(pan.view!.bounds)
        
        switch (pan.state) {
            case .Began:
                self.interactive = true
                self.locationsListController.performSegueWithIdentifier("dismissList", sender: self)
                break
            
            case .Changed:
                self.updateInteractiveTransition(d)
            
        default:
            self.interactive = false
            if (d > 0.4) {
                self.finishInteractiveTransition()
            } else {
                self.cancelInteractiveTransition()
            }
        }
        
    }
    
    func handleButtonPress() {
        self.locationsListController.performSegueWithIdentifier("dismissList", sender: self)
    }
    
    func handleTapGesture(tap: UITapGestureRecognizer) {
        if tap.state == .Ended {
            self.locationsListController.performSegueWithIdentifier("dismissList", sender: self)
        }
    }

    
    //MARK: Transition Delegate
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }
    
    
}
