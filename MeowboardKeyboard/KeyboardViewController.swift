//
//  KeyboardViewController.swift
//  MeowboardKeyboard
//
//  Created by Charles Pletcher on 9/22/14.
//  Copyright (c) 2014 Charles Pletcher. All rights reserved.
//

import UIKit

class KeyboardViewController: UIInputViewController {

    var mainView: UIView!

    var API_KEY = "dc6zaTOxFJmzC"

    override func updateViewConstraints() {
        super.updateViewConstraints()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var xibViews = NSBundle.mainBundle().loadNibNamed("Keyboard", owner: self, options: nil)

        self.mainView = xibViews[0] as UIView
        self.view.addSubview(mainView)

        for view in self.mainView.subviews as [UIButton] {
            view.addTarget(self, action: "didTapButton:", forControlEvents: .TouchUpInside)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }

    func cleanQuery(query: String) -> String {
        return query.stringByReplacingOccurrencesOfString(" ", withString: "+", options: nil, range: nil).lowercaseString
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

    func getAndInsertRandomGifUrl(query: String, proxy: UITextDocumentProxy) {
        var cleanedQuery = cleanQuery(query)

        var url = NSURL(string: "http://api.giphy.com/v1/gifs/search?q=\(cleanedQuery)&api_key=\(API_KEY)")
        var task = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, response, error) in
            var parsedData : NSArray = self.parseJson(data)["data"] as NSArray
            var imageObject : NSDictionary = parsedData[0] as NSDictionary
            var images : NSDictionary = imageObject["images"] as NSDictionary
            var fixedWidth : NSDictionary = images["fixed_width"] as NSDictionary
            var gifUrl : String = fixedWidth["url"] as String

            proxy.insertText(gifUrl)
        }

        task.resume()
    }

    func parseJson(data: NSData) -> NSDictionary {
        var error : NSError?
        var dictionary : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as NSDictionary

        return dictionary
    }
}
