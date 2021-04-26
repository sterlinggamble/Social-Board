//
//  AddTopicViewController.swift
//  Social Board
//
//  Created by Sterling Gamble on 4/10/21.
//

import UIKit
import CoreData

protocol AddTopicDelegate {
    func reloadView()
}

class AddTopicViewController: UIViewController {
    private let textFieldLine: CALayer = {
        let line = CALayer()
        line.backgroundColor = #colorLiteral(red: 0.7764705882, green: 0.7764705882, blue: 0.7843137255, alpha: 0.8)
        return line
    }()
    
    private let textFieldLine2: CALayer = {
        let line = CALayer()
        line.backgroundColor = #colorLiteral(red: 0.7764705882, green: 0.7764705882, blue: 0.7843137255, alpha: 0.8)
        return line
    }()
    
    private let titleField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Title"
        textField.borderStyle = .none
        textField.font = .systemFont(ofSize: 22, weight: .semibold)
        return textField
    }()
    
    private let contentURLField: UITextField = {
        let textfield = UITextField()
        textfield.placeholder = "Enter content URL"
        textfield.borderStyle = .none
        return textfield
    }()
    
    private let addButton: UIButton = {
        let button = UIButton()
        button.tintColor = .systemBlue
        button.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        return button
    }()
    
    private let addedContentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.text = "Added Content"
        label.textColor = .systemBlue
        return label
    }()
    
    var tableView = UITableView()
    
    var addTopicDelegate: AddTopicDelegate!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var twitterAPI = TwitterAPI()
    
    var content = [Any]()
    var tweets = [NSManagedObject]()
    var redditPosts = [NSManagedObject]()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
            
        navigationController?.navigationBar.backgroundColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(onCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(onDone))
        
        addButton.addTarget(self, action: #selector(addContent), for: .touchUpInside)
        
        // nav shadow
        navigationController?.navigationBar.layer.shadowColor = UIColor.lightGray.cgColor
        navigationController?.navigationBar.layer.shadowOpacity = 0.8
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 16, height: 0.5)
        navigationController?.navigationBar.layer.shadowRadius = 0
        
        textFieldLine.frame = CGRect(x: 0, y: 44, width: view.bounds.width, height: 1)
        titleField.frame = CGRect(x: 16, y: 140, width: view.bounds.width-32, height: 26)
        contentURLField.frame = CGRect(x: 16, y: 202, width: view.bounds.width-53, height: 36)
        addButton.frame = CGRect(x: contentURLField.bounds.width+21, y: 202, width: 30, height: 32)
        textFieldLine2.frame = CGRect(x: 0, y: 37, width: view.bounds.width, height: 1)
        addedContentLabel.frame = CGRect(x: 16, y: 255, width: 143, height: 25)
        
        titleField.layer.addSublayer(textFieldLine)
        contentURLField.layer.addSublayer(textFieldLine2)
        
        view.addSubview(titleField)
        view.addSubview(contentURLField)
        view.addSubview(addButton)
        view.addSubview(addedContentLabel)
        
        // content table view
        let frame = CGRect(x: 0, y: 283, width: view.bounds.width, height: view.bounds.height-274)
        tableView = UITableView(frame: frame, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .white
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(TweetCell.self, forCellReuseIdentifier: "TweetCell")
        view.addSubview(tableView)
    }
    

    @objc func onCancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc func onDone() {
        if let topicName = titleField.text {
            // create topic managed object
            let entity = NSEntityDescription.entity(forEntityName: "Topic", in: context)
            let newTopic = NSManagedObject(entity: entity!, insertInto: context)
            newTopic.setValue(topicName, forKey: "title")
            
            // save topic
            do {
                try context.save()
            } catch {
                print("Saved Topic error")
            }
            
            var newTweets = [NSObject]()
//            var newRedditPosts = [NSObject]()

            // create content objects
            for post in content {
                if let tweet = post as? Tweet {
                    let tweetEntity = NSEntityDescription.entity(forEntityName: "Tweet", in: context)
                    let newTweet = NSManagedObject(entity: tweetEntity!, insertInto: context)
                    newTweet.setValue(String(tweet.id!), forKey: "id")
                    newTweets.append(newTweet)

                } else if let _ = post as? RedditPost {

                }
            }
            
            // add content relationships
            let tweetsMO = newTopic.mutableSetValue(forKey: "tweets")
            tweetsMO.addObjects(from: newTweets)

            do {
                try newTopic.managedObjectContext?.save()
            } catch {
                print("Failed Saving Entity Relationship")
                print(error.localizedDescription)
            }

            dismiss(animated: true, completion: nil)
        } else {
            // alert topic title is missing
        }
 
    }
    
    @objc func addContent() {
        if let text = contentURLField.text {
            if text.contains("twitter.com") {
                let last = text.components(separatedBy: "/").last
                // url from share button adds '?s=20' at the end
                let stringID = last?.components(separatedBy: "?").first
                
                // check if id is valid by casting to int
                if let stringID = stringID, let _ = Int(stringID) {
                    twitterAPI.tweetInfo(id: stringID) { (tweet) in
                        self.content.append(tweet)
                        

                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            } else if text.contains("reddit.com") {
                
            }
            contentURLField.text = ""
            self.view.endEditing(true)
        }
        
    }
}


extension AddTopicViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let tweet = content[indexPath.row] as? Tweet {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TweetCell") as! TweetCell
            cell.configure(tweet: tweet)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.width-32, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = .systemFont(ofSize: 17)
        
        if let tweet = content[indexPath.row] as? Tweet {
            label.text = tweet.text
        }
        label.sizeToFit()
        
        return label.frame.height + 88
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
}
