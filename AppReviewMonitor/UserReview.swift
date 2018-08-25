//
//  UserReview.swift
//  AppReviewMonitor
//
//  Created by Kumar, Sunil on 25/08/18.
//  Copyright © 2018 AppScullery. All rights reserved.
//

import Foundation

struct UserReview : Codable {
    var id : Int64 = 0
    var title : String!
    var date : String!
    var dateInt : Int64 = 0
    var stars : Int = 0
    var version : String!
    var author : String!
    var reviewText : String!
    var reviewHTML : String!
    
    public init() {
        
    }
    
    enum CodingKeys: String, CodingKey
    {
        case id
        case title
        case date
        case dateInt
        case stars
        case version
        case author
        case review
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(dateInt, forKey: .dateInt)
        try container.encode(stars, forKey: .stars)
        try container.encode(version, forKey: .version)
        try container.encode(author, forKey: .author)
        try container.encode(reviewText, forKey: .review)
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(Int64.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.date = try container.decode(String.self, forKey: .date)
        self.dateInt = try container.decode(Int64.self, forKey: .dateInt)
        self.stars = try container.decode(Int.self, forKey: .stars)
        self.version = try container.decode(String.self, forKey: .version)
        self.author = try container.decode(String.self, forKey: .author)
        self.reviewText = try container.decode(String.self, forKey: .review)

    }
}
