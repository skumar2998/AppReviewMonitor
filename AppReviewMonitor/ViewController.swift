//
//  ViewController.swift
//  AppReviewMonitor
//
//  Created by Kumar, Sunil on 16/06/18.
//  Copyright © 2018 AppScullery. All rights reserved.
//

import UIKit
import Alamofire
import SWXMLHash
import Firebase

class ViewController: UIViewController {
    
    var pagesArray: [URL] = []
    var reviewsList: [UserReview] = []
    var currentPageIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.startReviewDownLoad(notification:)), name: Notification.Name("startReviewDownLoad"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.continueReviewDownLoad(notification:)), name: Notification.Name("continueReviewDownLoad"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reviewDownLoadComplete(notification:)), name: Notification.Name("reviewDownLoadComplete"), object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        DispatchQueue.global(qos: .background).async {
//            self.prepareForDownload(parseUrl: "https://itunes.apple.com/us/rss/customerreviews/id=439763870/sortby=mostrecent/xml")
//        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {


            let dataBaseRef = Database.database().reference()

            dataBaseRef.child("439763870").observe(.value) { (dataSnapshot) in
                let postDict = dataSnapshot.value as? [String : AnyObject] ?? [:]
                for (_, record) in postDict.enumerated() {

                    let jsonString = record.value as! String

                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            let jsonDecoder = JSONDecoder()
                            let userReview = try jsonDecoder.decode(UserReview.self, from: jsonData)
                            self.reviewsList.append(userReview)
                        }
                        catch {

                        }
                    }
                }

                for (index, reviewItem) in self.reviewsList.enumerated() {

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    let reviewUpdatedDate = dateFormatter.date(from: reviewItem.date)
                    dateFormatter.dateFormat = "dd-MM-yyyy HH:MM"
                    let reviewUpdated = dateFormatter.string(from: reviewUpdatedDate!)

                    print("\(index)-----------------------------------------")
                    print("Id: \(reviewItem.id)")
                    print("Date: \(reviewUpdated)")
                    print("Author: \(reviewItem.author as String)")
                    print("App Version: \(reviewItem.version as String)")
                    print("Stars: \(reviewItem.stars)")
                    print("Title: \(reviewItem.title as String)")
                    print("Review: \(reviewItem.reviewText as String)")
                    // print("Review (Html): \(reviewHTML)")
                }

            }

        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareForDownload(parseUrl: String) {
        print("Parsing Url : \(parseUrl)")
        Alamofire.request(parseUrl, parameters: nil)
            .response { response in
                if let data = response.data {
                    
                    let xml = SWXMLHash.parse(data)
                    
                    let feedXml = xml["feed"]
                    
                    let linkArray = feedXml["link"]
                    var lastPageNo: Int = 0
                    for linkElement in linkArray.all {
                        let linkType = linkElement.element?.attribute(by:"rel")?.text
                        
                        if(linkType == "last") {
                            if let lastUrlString = linkElement.element?.attribute(by:"href")?.text {
                                if let startingRange = lastUrlString.range(of: "/us/rss/customerreviews/page=") {
                                    if let endingRange = lastUrlString.range(of: "/id=439763870/sortby=mostrecent/xml") {
                                        let pageNumberRange = startingRange.upperBound..<endingRange.lowerBound
                                        let pageNumberString = lastUrlString[pageNumberRange]
                                        lastPageNo = Int(pageNumberString)!
                                    }
                                }
                            }
                        }
                    }
                    
                    print("Total Number of Pages \(lastPageNo)")
                    
                    for pageCount in 1...lastPageNo {
                        self.pagesArray.append(URL(string: "https://itunes.apple.com/us/rss/customerreviews/page=\(pageCount)/id=439763870/sortby=mostrecent/xml")!)
                    }
                    
                    NotificationCenter.default.post(name: Notification.Name("startReviewDownLoad"), object: nil)
                }
        }
    }
    
    
    @objc func startReviewDownLoad(notification: Notification){
        self.currentPageIndex = 0;
        NotificationCenter.default.post(name: Notification.Name("continueReviewDownLoad"), object: nil)
        
    }
    
    @objc func continueReviewDownLoad(notification: Notification){
        
        if(self.currentPageIndex < self.pagesArray.count) {
            self.downloadReviews(parseUrl: self.pagesArray[self.currentPageIndex])
            self.currentPageIndex = self.currentPageIndex + 1;
        } else {
            NotificationCenter.default.post(name: Notification.Name("reviewDownLoadComplete"), object: nil)
        }
        
    }
    
    @objc func reviewDownLoadComplete(notification: Notification){
        print("Total Number of Reviews Downloaded : \(self.reviewsList.count)")
        
        let dataBaseRef = Database.database().reference()
        
        for (index, reviewItem) in self.reviewsList.enumerated() {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let reviewUpdatedDate = dateFormatter.date(from: reviewItem.date)
            dateFormatter.dateFormat = "dd-MM-yyyy HH:MM"
            let reviewUpdated = dateFormatter.string(from: reviewUpdatedDate!)
            
            print("\(index)-----------------------------------------")
            print("Id: \(reviewItem.id)")
            print("Date: \(reviewUpdated)")
            print("Author: \(reviewItem.author as String)")
            print("App Version: \(reviewItem.version as String)")
            print("Stars: \(reviewItem.stars)")
            print("Title: \(reviewItem.title as String)")
            print("Review: \(reviewItem.reviewText as String)")
            // print("Review (Html): \(reviewHTML)")
            
            

            
            
            dataBaseRef.child("439763870/\(reviewItem.id)").observeSingleEvent(of: .value) { (snapshot) in
                if !snapshot.exists() {
                    do {
                        let jsonEncoder = JSONEncoder()
                        let jsonData = try jsonEncoder.encode(reviewItem)
                        if let jsonObject = String(data: jsonData, encoding: .utf8) {
                            dataBaseRef.child("439763870/\(reviewItem.id)").setValue(jsonObject)
                        }
                        
                        
                        
                    } catch {
                        
                    }
                } else {
                    print("439763870/\(reviewItem.id) Exists")
                }
            }
            
            


            

            

            
        }
        

        
    }
    
    func downloadReviews(parseUrl: URL) {
        print("Parsing Url : \(parseUrl)")
        Alamofire.request(parseUrl, parameters: nil)
            .response { response in
                if let data = response.data {
                    
                    let xml = SWXMLHash.parse(data)
                    
                    let feedXml = xml["feed"]
                    
                    for entry in feedXml["entry"].all {
                        if entry["category"].element != nil {
                            
                        } else {
                            
                            var reviewItem = UserReview()
                            reviewItem.id = Int64(entry["id"].element!.text)!
                            reviewItem.title = entry["title"].element!.text
                            reviewItem.date = entry["updated"].element!.text
                            reviewItem.stars = Int(entry["im:rating"].element!.text)!
                            reviewItem.version = entry["im:version"].element!.text
                            reviewItem.author = entry["author"]["name"].element!.text
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                            if let reviewUpdatedDate = dateFormatter.date(from: reviewItem.date) {
                                reviewItem.dateInt = Int64(reviewUpdatedDate.timeIntervalSince1970)
                            }
                            
                            
                            
                            let contentArray = entry["content"]
                            for contentElement in contentArray.all {
                                let contentType = contentElement.element?.attribute(by:"type")?.text
                                if contentType == "text" {
                                    reviewItem.reviewText = contentElement.element!.text
                                } else {
                                    reviewItem.reviewHTML = contentElement.element!.text
                                }
                            }
                            
                            self.reviewsList.append(reviewItem)
                            
                            
                        }
                    }
                    
                }
                
                NotificationCenter.default.post(name: Notification.Name("continueReviewDownLoad"), object: nil)
                
        }
    }
}

