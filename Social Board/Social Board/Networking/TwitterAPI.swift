//
//  TwitterAPI.swift
//  Social Board
//
//  Created by Sterling Gamble on 4/14/21.
//

import Foundation

class TwitterAPI {
    let baseURL = "https://api.twitter.com/"
    
    // Access token not fetched in the contructor so that we have a consistent token throughout all views
    func fetchAccessToken(completion: @escaping () -> Void) -> Void {
        let clientKey = TWITTERCLIENTKEY
        let clientSecret = TWITTERSECRETKEY
        
        // Encoding
        let encodedClientKey = clientKey.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlUserAllowed)!
        let encodedSecretKey = clientSecret.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlUserAllowed)!
        
        let keySecret = encodedClientKey + ":" + encodedSecretKey
        let data = keySecret.data(using: .utf8)
        let b64EncodedKey = "Basic " + (data?.base64EncodedString())!
    
        // Authorization Headers
        var request = URLRequest(url: URL(string: "https://api.twitter.com/oauth2/token")!)
        request.httpMethod = "POST"
        request.addValue(b64EncodedKey, forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")

        let authData = "grant_type=client_credentials".data(using: .utf8)!
        request.setValue("\(authData.count)", forHTTPHeaderField: "Content-Length")
        request.httpBody = authData
        
        // Authorization Token Retrevial
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print(httpResponse.statusCode)
            }
            
            do {
                let response = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>
                let accessToken = response["access_token"] as! String
                UserDefaults.standard.set(accessToken, forKey: "TwitterAccessToken")
                print("Access Token: " + accessToken)
                completion()
            } catch {
                print("JSON Error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func retweeters(id: Int, count: Int, completion: @escaping ([Int]) -> Void) -> Void {
        let searchURL = baseURL + "1.1/statuses/retweeters/ids.json?id=\(id)&count=\(count)"
        let accessToken = UserDefaults.standard.string(forKey: "TwitterAccessToken")!
        
        var request = URLRequest(url: URL(string: searchURL)!)
        request.httpMethod = "GET"
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
                
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print(httpResponse.statusCode)
            }
            
            do {
                let response = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>
                completion(response["ids"] as! [Int])
            } catch {
                print("JSON Error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func tweetInfo(id: String, completion: @escaping (Tweet) -> Void) -> Void {
        let searchURL = baseURL + "1.1/statuses/show.json?id=\(id)"
        let accessToken = UserDefaults.standard.string(forKey: "TwitterAccessToken")!
        
        var request = URLRequest(url: URL(string: searchURL)!)
        request.httpMethod = "GET"
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            do {
//                let response = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>
//                completion(response)
                let decoded = try JSONDecoder().decode(Tweet.self, from: data!)
                completion(decoded)
            } catch {
                print("JSON Error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func userTimeline(userID: Int, count: Int, completion: @escaping ([Tweet]) -> Void) -> Void {
        let searchURL = baseURL + "1.1/statuses/user_timeline.json?user_id=\(userID)&count=\(count)"
        let accessToken = UserDefaults.standard.string(forKey: "TwitterAccessToken")!
        
        var request = URLRequest(url: URL(string: searchURL)!)
        request.httpMethod = "GET"
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            do {
                let decoded = try JSONDecoder().decode([Tweet].self, from: data!)
                completion(decoded)
            } catch {
                print("JSON Error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func favoriteList(userID: Int, count: Int, completion: @escaping ([Tweet]) -> Void) -> Void {
        let searchURL = baseURL + "1.1/statuses/user_timeline.json?user_id=\(userID)&count=\(count)"
        let accessToken = UserDefaults.standard.string(forKey: "TwitterAccessToken")!
        
        var request = URLRequest(url: URL(string: searchURL)!)
        request.httpMethod = "GET"
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            do {
//                let response = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>
                let decoded = try JSONDecoder().decode([Tweet].self, from: data!)
                completion(decoded)
            } catch {
                print("JSON Error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
   
    
    
}
