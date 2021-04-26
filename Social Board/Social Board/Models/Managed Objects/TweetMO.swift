//
//  TweetMO.swift
//  Social Board
//
//  Created by Sterling Gamble on 4/19/21.
//

import Foundation
import CoreData

class TweetMO: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var contentScore: NSNumber?
    @NSManaged var collabScore: NSNumber?
    @NSManaged var overallScore: NSNumber?
    @NSManaged var topic: TopicMO?
}
