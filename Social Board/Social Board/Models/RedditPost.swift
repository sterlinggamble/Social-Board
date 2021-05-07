//
//  RedditPost.swift
//  Social Board
//
//  Created by Sterling Gamble on 4/14/21.
//

import Foundation

struct RedditPost {
    var subreddit: String?
    var selftext: String?
    var author: String?
    var title: String?
    var id: String?
    var subredditImg: String?
    var contentScore: Double? = 0.0
    var collabScore: Double? = 0.0
    var overallScore: Double? = 0.0
}
