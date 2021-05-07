//
//  RedditPostMO.swift
//  Social Board
//
//  Created by Sterling Gamble on 5/3/21.
//

import Foundation
import CoreData

class RedditPostMO: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var contentScore: NSNumber?
    @NSManaged var collabScore: NSNumber?
    @NSManaged var overallScore: NSNumber?
    @NSManaged var topic: TopicMO?
}
