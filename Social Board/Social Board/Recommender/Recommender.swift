//
//  Recommender.swift
//  Social Board
//
//  Created by Sterling Gamble on 4/14/21.
//

import Foundation

class Recommender {
    let twitterAPI = TwitterAPI()
    var seedTweetCount = 0
    var tweets = [Int:Tweet]() // {tweet id: object}
    var tweetInteractors = [Int: Set<Int>]() // {user id: tweet id}
    var tweetAuthors = Set<Int>() // author ids
    
    let redditAPI = RedditAPI()
    var redditPosts = [String: RedditPost]()
    var redditUsers = Set<String>()
    var subreddits = Set<String>()
    var redditIDs = [String]()
    var favRedditIDs = Set<String>()
    var seedRedditPostCount = 0
    
    // filtering data
    var favTweetIDs = Set<Int>()
    var tweetIDs = [Int]()
    var twitterUserIDs = [Int]()
    var seedTweets = [Int: Set<Int>]() // tracks where candiate tweets come from
    var seedTwitterUsers = [Int: Set<Int>]() // tracks where a canidate user came from
    
    func run(content: [Any], completion: @escaping ([Any]) -> Void) {
        print("running recommender")
        // Data Collection and Preparation
        fetchUsers(content: content) {
            self.fetchData {
                // once data has been fetched start filtering candidate content
                
                // content based filtering using TF-IDF content similarity
                print("Started Content")
                self.contentBased()
                
                // collaborative based filtering
                print("Started Collab")
                self.collabFilter()
            
                
                print(self.tweetIDs.count)
                
                completion(self.getTopResults())
            }
        }
    }
    
    func fetchUsers(content: [Any], completion: @escaping () -> Void) {
        print("fetching users")
        let group = DispatchGroup()
        for post in content {
            group.enter()
            if let post = post as? Tweet {
                // Data Collection
                tweetAuthors.insert((post.user?.id)!)
                tweetIDs.append(post.id!)
                favTweetIDs.insert(post.id!)
                seedTweetCount += 1
                
                twitterAPI.retweeters(id: post.id!, count: 2) { (retweeters) in
                    for id in retweeters {
                        if self.tweetInteractors[id] != nil {
                            self.tweetInteractors[id]?.insert(post.id!)
                        } else {
                            let interactions: Set = [post.id!]
                            self.tweetInteractors[id] = interactions
                        }
                        
                        // for content based filtering
                        // store from which tweets did the current candidate user came from
                        if self.seedTwitterUsers[id] != nil {
                            self.seedTwitterUsers[id]?.insert(post.id!)
                        } else {
                            self.seedTwitterUsers[id] = Set([post.id!])
                        }
                    }
                    
                    group.leave()
                }
                
            } else if let post = post as? RedditPost {
                redditPosts[post.id!] = post
                redditUsers.insert(post.author!)
                redditIDs.append(post.id!)
                favRedditIDs.insert(post.id!)
                subreddits.insert(post.subreddit!)
                seedRedditPostCount += 1
                group.leave()
//                // get commenters
//                redditAPI.postData(postID: post.id!) { data in
//
//                }
                
                
            }
        }
        group.notify(queue: .global()) {
            completion()
        }
    }
    
    func fetchData(completion: @escaping () -> Void) {
        print("fetching data")
        let group = DispatchGroup()
        // for each tweet author get their /user_timeline
        for author in tweetAuthors {
            group.enter()
            twitterAPI.userTimeline(userID: author, count: 2) { (timelineTweets) in
                let tweetIDs = [Int]()
                for tweet in timelineTweets {
                    self.tweets[tweet.id!] = tweet
                    self.tweetIDs.append(tweet.id!) // for filtering
                }
                
                if self.tweetInteractors[author] != nil {
                    self.tweetInteractors[author]?.formUnion(tweetIDs)
                } else {
                    self.tweetInteractors[author] = Set(tweetIDs)
                }
                group.leave()
            }
        }
        
        // for each interactor get their favorites
        for (user, _) in tweetInteractors {
            group.enter()
            twitterAPI.favoriteList(userID: user, count: 2) { (tweets) in
                let tweetIDs = [Int]()
                for tweet in tweets {
                    self.tweets[tweet.id!] = tweet
                    self.tweetIDs.append(tweet.id!) // WARNING: Might cause duplicates
                    
                    // for content based filtering
                    // store from which tweet(s) did the current candidate tweet came from
                    self.seedTweets[tweet.id!] = self.seedTwitterUsers[user]
                }
                
                if self.tweetInteractors[user] != nil {
                    self.tweetInteractors[user]?.formUnion(tweetIDs)
                } else {
                    self.tweetInteractors[user] = Set(tweetIDs)
                }
                
                
                self.twitterUserIDs.append(user) // for filtering
                
                group.leave()
            }
        }
        
        print("fetching reddit user posts")
        for username in redditUsers {
            group.enter()
            redditAPI.userPosts(username: username) { posts in
                for post in posts {
                    if self.redditPosts[post.id!] == nil {
                        self.redditPosts[post.id!] = post
                        self.redditIDs.append(post.id!)
                    }
                    
                }
                
                group.leave()
            }
        }
        
        print("fetching subreddit posts")
        for subreddit in subreddits {
            group.enter()
            redditAPI.subredditPosts(subreddit: subreddit) { posts in
                for post in posts {
                    if self.redditPosts[post.id!] == nil {
                        self.redditPosts[post.id!] = post
                        self.redditIDs.append(post.id!)
                    }
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: .global()) {
            completion()
        }
    }
    
    // MARK: Content Filter
    func contentBased() {
        
        
        // MARK: Twitter
        var words = [String]()
        var splitTweets = [[String]]()
        let separators = CharacterSet(charactersIn: "./,; ")
        let tweetImageURL = "https://t.co/"
        
        // separate and retrieve all the words from a tweet
        for id in tweetIDs {
            var text = tweets[id]?.text
            
            // for each tweet do not include the image link
            if let dotRange = text?.range(of: tweetImageURL) {
                text!.removeSubrange(dotRange.lowerBound..<text!.endIndex)
            }
            
            // lower case in order to accurately find similar words
            text = text?.lowercased()
            
            guard let texts = text?.components(separatedBy: separators) else {
                continue
            }
            words.append(contentsOf: texts)
            
            var unqiueText = texts.filter { $0 != "" }
            for i in 0..<unqiueText.count {
                unqiueText[i] = unqiueText[i].lowercased()
            }
            
            splitTweets.append(unqiueText)
        }
        
        // remove duplicates
        var unqiueWords: Set<String> = []
        for word in words {
            unqiueWords.insert(word)
        }

        // remove any empty words
        for word in unqiueWords {
            if word.count == 0 {
                unqiueWords.remove(word)
            }
        }
        
        // Term Frequency
        // TF(t) = (Number of times term t appears in a document) / (Total number of terms in the document).
        print("Calculating TF")
        // for each word in the set compute TF for each tweet
        var tfDic: [String: [Double]] = [:]
        for word in unqiueWords {
            var tfs = [Double]()
            for tweet in splitTweets {
                // count num word appears in tweet
                var count = 0
                for val in tweet {
                    if val == word {
                        count += 1
                    }
                }
                let tf = Double(count) / Double(tweet.count) // calculate tf
                tfs.append(tf)
            }
            tfDic[word] = tfs // add to TF dictionary
        }
        
        // Inverse Document Frequency
        // IDF(t) = log_e(Total number of documents / Number of documents with term t in it).
        print("Calculating IDF")
        var idfDic: [String:Double] = [:]
        for (term, tfs) in tfDic {
            var count = 0
            for tf in tfs {
                if tf > 0.0 {
                    count += 1
                }
            }
            idfDic[term] = log(Double(tfs.count)) - log(Double(count))
        }
        
        // TF*IDF Matrix
        var matrix = [[Double]]()
        
        for i in 0..<tweets.count {
            var vectors = [Double]()
            for word in unqiueWords {
                let tfs = tfDic[word]!
                let tfIDF = tfs[i] * idfDic[word]!
                vectors.append(tfIDF)
            }
            matrix.append(vectors)
        }
        print("Calculating cosine similarity")
        print("Matrix count: \(matrix.count)")
        // Calculate cosine similarity compared to each seed tweet
        for i in 0..<seedTweetCount {
            for j in seedTweetCount-1..<matrix.count {
                let score = sim(vectorA: matrix[i], vectorB: matrix[j])
                let currentScore = tweets[tweetIDs[j]]?.contentScore
                tweets[tweetIDs[j]]?.contentScore = max(score, currentScore ?? 0.0)
            }
        }
        
        // MARK: Reddit
        words.removeAll()
        var splitPosts = [[String]]()
        
        // separate and retrieve all the words from a tweet
        for (index, id) in redditIDs.enumerated() {
            var text = redditPosts[id]?.title

            // lower case in order to accurately find similar words
            text = text?.lowercased()
            
            guard let texts = text?.components(separatedBy: separators) else {
                redditIDs.remove(at: index)
                continue
            }
            words.append(contentsOf: texts)
            
            var unqiueText = texts.filter { $0 != "" }
            for i in 0..<unqiueText.count {
                unqiueText[i] = unqiueText[i].lowercased()
            }
           
            splitPosts.append(unqiueText)
        }
        
        // remove duplicates
        unqiueWords.removeAll()
        for word in words {
            unqiueWords.insert(word)
        }

        // remove any empty words
        for word in unqiueWords {
            if word.count == 0 {
                unqiueWords.remove(word)
            }
        }
        
        // Term Frequency
        // TF(t) = (Number of times term t appears in a document) / (Total number of terms in the document).
        print("Calculating Reddit TF")
        // for each word in the set compute TF for each tweet
        tfDic.removeAll()
        for word in unqiueWords {
            var tfs = [Double]()
            for post in splitPosts {
                // count num word appears in tweet
                var count = 0
                for val in post {
                    if val == word {
                        count += 1
                    }
                }
                let tf = Double(count) / Double(post.count) // calculate tf
                tfs.append(tf)
            }
            tfDic[word] = tfs // add to TF dictionary
        }
        print("TF DIC")
        print(tfDic.count)
        print(splitPosts.count)
        print(redditPosts.count)
        print(redditIDs.count)
        // Inverse Document Frequency
        // IDF(t) = log_e(Total number of documents / Number of documents with term t in it).
        print("Calculating Reddit IDF")
        idfDic.removeAll()
        for (term, tfs) in tfDic {
            var count = 0
            for tf in tfs {
                if tf > 0.0 {
                    count += 1
                }
            }
            idfDic[term] = log(Double(tfs.count)) - log(Double(count))
        }
        
        // TF*IDF Matrix
        matrix.removeAll()
        
        for i in 0..<redditIDs.count {
            var vectors = [Double]()
            for word in unqiueWords {
                let tfs = tfDic[word]!
                let tfIDF = tfs[i] * idfDic[word]!
                vectors.append(tfIDF)
            }
            matrix.append(vectors)
        }
        print("Calculating Reddit cosine similarity")
        print("Matrix count: \(matrix.count)")
        // Calculate cosine similarity compared to each seed tweet
        for i in 0..<seedRedditPostCount {
            for j in seedRedditPostCount-1..<matrix.count {
                let score = sim(vectorA: matrix[i], vectorB: matrix[j])
                let currentScore = redditPosts[redditIDs[j]]?.contentScore
                redditPosts[redditIDs[j]]?.contentScore = max(score, currentScore ?? 0.0)
            }
        }
    }
    
    // MARK: Cosine Similarity Score
    // cos sim = (vector A * vector B) / (sqrt((vector A) * 2) * sqrt((vector A) * 2))
    func sim(vectorA: [Double], vectorB: [Double]) -> Double {
        var top = 0.0
        var bottom1 = 0.0
        var bottom2 = 0.0
        for i in 0..<vectorA.count {
            top += vectorA[i] * vectorB[i]
            bottom1 += vectorA[i] * vectorA[i]
            bottom2 += vectorB[i] * vectorB[i]
        }
        
        let bottom = bottom1.squareRoot() * bottom2.squareRoot()
        return top / bottom
    }
    
    // MARK: Collab Filter
    func collabFilter() {
        // rows = user vectors, cols = tweets
        var matrix = Array(repeating: Array(repeating: 0.0, count: tweetIDs.count), count: twitterUserIDs.count)
        
        // set interaction values in the matrix
        for i in 0..<matrix.count {
            for j in 0..<matrix[0].count {
                let userID = twitterUserIDs[i]
                let tweetID = tweetIDs[j]
                let interactions = tweetInteractors[userID]
                
                if interactions?.contains(tweetID) == true {
                    matrix[i][j] = 1.0
                }
            }
        }
        
        // set user vector values
        var userVector = [Double]()
        for id in tweetIDs {
            if favTweetIDs.contains(id) {
                userVector.append(1.0)
            } else {
                userVector.append(0.0)
            }
        }
        
        for i in 0..<userVector.count {
            if userVector[i] == 0.0 {
                // find the most similar user who interacted with that tweet
                for vector in matrix {
                    if vector[i] == 1.0 {
                        // get the highest cosine similarity score for each tweet
                        let simScore = sim(vectorA: userVector, vectorB: vector)
                        userVector[i] = max(userVector[i], simScore)
                    }
                }
                
            }
        }
        
        // update collab score for each tweet
        for (index, id) in tweetIDs.enumerated() {
            tweets[id]?.collabScore = userVector[index]
        }
    }
    
    // MARK: Results
    func getTopResults() -> [Any] {
        print("getting results")
        var recommendations = [Any]() // TODO: change to Any
        for (id, tweet) in tweets {
            if !favTweetIDs.contains(id) {
                tweets[id]?.overallScore = (tweet.collabScore ?? 0.0) + (tweet.contentScore ?? 0.0)
                if tweets[id]?.overallScore != 0.0 { // exclude non relevant content
                    recommendations.append(tweets[id]!)
                }
            }
        }
        
        var num = 0
        for (id, post) in redditPosts {
            if !favRedditIDs.contains(id) {
                redditPosts[id]?.overallScore = (post.collabScore ?? 0.0) + (post.contentScore ?? 0.0)
                if redditPosts[id]?.overallScore != 0.0 { // exclude non relevant content
//                    recommendations.append(tweets[id]!)
                    recommendations.append(redditPosts[id]!)
                    num += 1
                }
            }
        }
        print("Reddit Recommendations: \(num)")
        
        print("Recommendation Count: \(recommendations.count)")
//        recommendations = recommendations.sorted(by: {$0.overallScore! < $1.overallScore!})
        recommendations.sort { post1, post2 in
            let l = (post1 as? Tweet)?.overallScore ?? (post1 as? RedditPost)?.overallScore
            let r = (post2 as? Tweet)?.overallScore ?? (post2 as? RedditPost)?.overallScore
            return l! < r!
        }
        
        
        if recommendations.count > 50 {
            let slice = recommendations.prefix(50)
            var topRec = [Any]()
            for post in slice {
                topRec.append(post)
            }
            return topRec
        }
        
        return recommendations
        
    }
    
}
