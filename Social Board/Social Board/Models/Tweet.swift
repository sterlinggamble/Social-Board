//
//  Tweet.swift
//  Social Board
//
//  Created by Sterling Gamble on 4/11/21.
//

import Foundation

struct Tweet: Codable {
    var id: Int?
    var text: String?
    var user: TweetUser?
    var contentScore: Double? = 0.0 
    var collabScore: Double? = 0.0
    var overallScore: Double? = 0.0
}

struct TweetUser: Codable {
    var id: Int?
    var name: String?
    var screen_name: String?
    var profile_image_url_https: String?
}

//enum CodingKeys: String, CodingKey {
//    case screenName = "screen_name"
//}
