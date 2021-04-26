//
//  RedditPost.swift
//  Social Board
//
//  Created by Sterling Gamble on 4/14/21.
//

import Foundation

struct RedditPost: Codable {
    var subreddit: String?
    var selftext: String?
    var author_fullname: String?
    var title: String?
    var ups: String? // upvotes
}
