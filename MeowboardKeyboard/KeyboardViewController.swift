//
//  KeyboardViewController.swift
//  MeowboardKeyboard
//
//  Created by Charles Pletcher on 9/22/14.
//  Copyright (c) 2014 Charles Pletcher. All rights reserved.
//

import UIKit

class KeyboardViewController: UIInputViewController {
    
    let API_KEY = "dc6zaTOxFJmzC"
    var mainView: UIView!

    override func updateViewConstraints() {
        super.updateViewConstraints()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var xibViews = NSBundle.mainBundle().loadNibNamed("Keyboard", owner: self, options: nil)

        self.mainView = xibViews[0] as UIView
        self.view.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.view.addSubview(mainView)
        
        for subview in self.mainView.subviews as [AnyObject] {
            if let scrollView = subview as? UIScrollView {
                var contentRect: CGRect = CGRectZero
                
                for view in scrollView.subviews as [UIView] {
                    contentRect = CGRectUnion(contentRect, view.frame)
                    
                    for button in view.subviews as [UIButton] {
                        getDefaultGifAndSetAsButtonBackground(button)
                        button.addTarget(self, action: "didTapButton:", forControlEvents: .TouchUpInside)
                    }
                }
                
                scrollView.contentSize = contentRect.size;
            } else if let fixedView = subview as? UIView {
                for object in fixedView.subviews as [AnyObject] {
                    if let button = object as? UIButton {
                        button.addTarget(self, action: "didTapButton:", forControlEvents: .TouchUpInside)
                    }
                }
            }
        }
        
        var keyboardHeightConstraint: NSLayoutConstraint = NSLayoutConstraint(item: self.view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0.0, constant: 500.0)
        self.view.addConstraint(keyboardHeightConstraint)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func cleanQuery(query: String) -> String {
        return query.stringByReplacingOccurrencesOfString(" ", withString: "+", options: nil, range: nil).lowercaseString
    }
    
    func cleanTitle(title: String) -> String {
        return title.stringByReplacingOccurrencesOfString(" ", withString: "_", options: nil, range: nil).lowercaseString
    }

    func didTapButton(sender: AnyObject) {
        let button = sender as UIButton
        let title = button.titleForState(.Normal) as String!
        var proxy = textDocumentProxy as UITextDocumentProxy

        switch title {
        case "CHG" :
            self.advanceToNextInputMode()
        case "DEL" :
            while proxy.hasText() {
                proxy.deleteBackward()
            }
        default:
            getAndInsertRandomGifUrl(title, proxy: proxy)
        }
    }
    
    func getDefaultGifAndSetAsButtonBackground(button: UIButton) {
        var cleanedQuery = cleanQuery(button.titleForState(.Normal) as String!)
        var url = NSURL(string: "http://api.giphy.com/v1/gifs/search?q=\(cleanedQuery)&api_key=\(API_KEY)")
        var task = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, response, error) in
            if (error != nil) {
                return println(error)
            }
            
            // FIXME: We need to cut this down to one HTTP call,
            //        and we need to cache the images for ~ 1 day
            
            var parsedData: NSArray = self.parseJson(data)["data"] as NSArray
            var imageObject: NSDictionary = parsedData[0] as NSDictionary
            var images: NSDictionary = imageObject["images"] as NSDictionary
            var fixedWidth: NSDictionary = images["fixed_width"] as NSDictionary
            var gifUrlString: String = fixedWidth["url"] as String
            var gifUrl: NSURL = NSURL.URLWithString(gifUrlString)
            
            var imageTask = NSURLSession.sharedSession().dataTaskWithURL(gifUrl) {(imageData, imageResponse, imageError) in
                if (imageError != nil) {
                    return println(imageError)
                }
            
                var backgroundImage = UIImage.animatedImageWithData(imageData as NSData)
            
                button.setBackgroundImage(backgroundImage, forState: .Normal)
            }
            
            imageTask.resume()
            
        }
        
        task.resume()
    }

    func getAndInsertRandomGifUrl(query: String, proxy: UITextDocumentProxy) {
        var cleanedQuery = cleanQuery(query)
        var url = NSURL(string: "http://api.giphy.com/v1/gifs/search?q=\(cleanedQuery)&api_key=\(API_KEY)")
        var task = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, response, error) in
            if (error != nil) {
                return println(error)
            }
            var parsedData: NSArray = self.parseJson(data)["data"] as NSArray
            var imageObject: NSDictionary = parsedData[0] as NSDictionary
            var images: NSDictionary = imageObject["images"] as NSDictionary
            var fixedWidth: NSDictionary = images["fixed_width"] as NSDictionary
            var gifUrlString: String = fixedWidth["url"] as String
            
            // FIXME: Page through the list of available GIFs after the first click,
            //        inserting a new one each click.
            
            proxy.insertText(gifUrlString)
        }

        task.resume()
    }

    func parseJson(data: NSData) -> NSDictionary {
        var error: NSError?
        var dictionary: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as NSDictionary

        return dictionary
    }
}
