//
//  RedditAPI.swift
//  Social Board
//
//  Created by Sterling Gamble on 4/14/21.
//

import Foundation

class RedditAPI {
    
    // returns at most 25 top posts from a subreddit
    func subredditPosts(subreddit: String, completion: @escaping ([RedditPost]) -> Void) {
        let searchURL = "https://www.reddit.com/r/\(subreddit)/top.json"
        var request = URLRequest(url: URL(string: searchURL)!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { [self] (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print(httpResponse.statusCode)
            }
            
            do {
                let response = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>
                if let data = response["data"] as? Dictionary<String, Any> {
                    if let children = data["children"] as? [Dictionary<String, Any>] {
                        var posts = [RedditPost]()
                        for child in children {
                            let childData = child["data"] as? Dictionary<String, Any>
                            posts.append(self.convert(data: childData!))
                        }
                        completion(posts)
                    }
                }
                
            } catch {
                print("JSON Error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    // returns at most 25 posts from user
    func userPosts(username: String, completion: @escaping ([RedditPost]) -> Void) {
        let searchURL = "https://www.reddit.com/user/\(username)/.json"
        var request = URLRequest(url: URL(string: searchURL)!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print(httpResponse.statusCode)
            }
            
            do {
                let response = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>

                if let data = response["data"] as? Dictionary<String, Any> {
                    if let children = data["children"] as? [Dictionary<String, Any>] {
                        var posts = [RedditPost]()
                        for child in children {
                            let childData = child["data"] as? Dictionary<String, Any>
                            posts.append(self.convert(data: childData!))
                        }
                        completion(posts)
                    }
                }
                                
            } catch {
                print("JSON Error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func postData(postID: String, completion: @escaping (RedditPost) -> Void) {
        let searchURL = "https://www.reddit.com/comments/\(postID)/.json"
        var request = URLRequest(url: URL(string: searchURL)!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print(httpResponse.statusCode)
            }
            
            do {
                let response = try JSONSerialization.jsonObject(with: data!, options: []) as! [Dictionary<String, Any>]
            
                if let data = response[0]["data"] as? Dictionary<String, Any> {
                    if let children = data["children"] as? [Dictionary<String, Any>] {
                        // the first item contains the post data
                        if let child = children[0]["data"] as? Dictionary<String, Any> {
                            completion(self.convert(data: child))
                        }
                        
                    }
                }
                                
            } catch {
                print("JSON Error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    // fetches data pertaining to a subreddit
    // TODO: ["icon_img"] to get subreddit icon
    func subredditData(subreddit: String, completion: @escaping (Dictionary<String, Any>) -> Void ) {
        let searchURL = "https://www.reddit.com/r/\(subreddit)/about.json"
        var request = URLRequest(url: URL(string: searchURL)!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print(httpResponse.statusCode)
            }
            
            do {
                let response = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>

                if let data = response["data"] as? Dictionary<String, Any> {
                    completion(data)
                }
                                
            } catch {
                print("JSON Error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func convert(data: Dictionary<String, Any>) -> RedditPost {
        var post = RedditPost()
        let name = data["name"] as? String
        let index = name?.index(name!.startIndex, offsetBy: 3)
        
        post.id = String((name?[index!...])!)
        post.author = data["author"] as? String
        post.title = data["title"] as? String
        post.subreddit = data["subreddit"] as? String
        
        return post
    }
}
