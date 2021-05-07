//
//  TopicMO.swift
//  Social Board
//
//  Created by Sterling Gamble on 4/19/21.
//

import Foundation
import CoreData

class TopicMO: NSManagedObject {
    @NSManaged var title: String?
    @NSManaged var tweets: NSSet?
    @NSManaged var redditPosts: NSSet?
}
