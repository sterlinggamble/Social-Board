//
//  HomeViewController.swift
//  Social Board
//
//  Created by Sterling Gamble on 4/10/21.
//

import UIKit
import CoreData

class HomeViewController: UIViewController {
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.showsHorizontalScrollIndicator = false
        cv.register(TopicTagCell.self, forCellWithReuseIdentifier: "TopicTagCell")
        return cv
    }()
    
    var tableView = UITableView()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var topics = [Topic]()
    var content = [Any]()
    let api = TwitterAPI()
    let redditAPI = RedditAPI()
    
    // dictionary of tweets and reddit posts
    // each topic has a set of content ids

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(onAdd))
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        collectionView.frame = CGRect(x: 16, y: 0, width: view.bounds.width, height: 28)
        view.addSubview(collectionView)
        
        let tabBarHeight = tabBarController?.tabBar.frame.size.height
        let frame = CGRect(x: 0, y: 43, width: view.bounds.width, height: view.bounds.height-(43+tabBarHeight!))
        tableView = UITableView(frame: frame, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .white
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(TweetCell.self, forCellReuseIdentifier: "TweetCell")
        tableView.register(RedditPostCell.self, forCellReuseIdentifier: "RedditPostCell")
        view.addSubview(tableView)
        
        tableView.isHidden = true
        
        topics.append(Topic(title: "All"))
        
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        
    }
    
    // Add Content or Topic
    @objc func onAdd() {
        let vc = AddTopicViewController()
        vc.title = "Add Topic"
        vc.addTopicDelegate = self // must add
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = true
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
        
//        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        alert.addAction(UIAlertAction(title: "Add Topic", style: .default, handler: { (_) in
//        }))
//        alert.addAction(UIAlertAction(title: "Add Content", style: .default, handler: { (_) in
//        }))
//        present(alert, animated: true)
    }
    
    func loadData() {
        var topicsMOs = [NSManagedObject]()
        
        let topicsRequest = NSFetchRequest<NSManagedObject>(entityName: "Topic")
        
        do {
            topicsMOs = try context.fetch(topicsRequest)
        } catch {
            print("Fetch Error")
        }
            
        api.fetchAccessToken {
            // Convert Managed Objects to Models
            let group = DispatchGroup()
            
            for topic in topicsMOs {
                if let topic = topic as? TopicMO {
                    self.topics.append(Topic(title: topic.title!))
                    if let tweetsMO = topic.tweets as? Set<TweetMO> {
                        for tweetMO in tweetsMO {
                            group.enter()
                            self.api.tweetInfo(id: tweetMO.id!) { (tweet) in
                                self.content.append(tweet)
                                group.leave()
                            }
                        }
                    }
                    if let redditMOs = topic.redditPosts as? Set<RedditPostMO> {
                        for redditMO in redditMOs {
                            group.enter()
                            self.redditAPI.postData(postID: redditMO.id!) { post in
                                self.content.append(post)
                                group.leave()
                            }
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                print("Content Count: \(self.content.count)")
                self.collectionView.reloadData()
                self.test()
            }
        }
    }
    
    func test() {
        topics.append(Topic(title: "Basketball"))
        topics.append(Topic(title: "Finance"))
        topics.append(Topic(title: "Politics"))
        
        let recommender = Recommender()
        recommender.run(content: content) { (recommendations) in
            self.content += recommendations
                        
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.tableView.isHidden = false
            }
        }
        
    }

}


extension HomeViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // dynamically sizes the cell width to the label size
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.text = topics[indexPath.row].title
        label.sizeToFit()
        label.frame = CGRect(x: 15, y: 0, width: label.bounds.width, height: label.bounds.height)
        return CGSize(width: label.frame.width+30, height: 28)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 6)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return topics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopicTagCell", for: indexPath) as! TopicTagCell
        cell.topicLabel.text = topics[indexPath.row].title
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? TopicTagCell {
            // check if 'All' is selected
            if indexPath.row == 0 {
                
            }
            
            if cell.isChosen {
                // remove topic from the feed
            } else {
                //
            }
            
            cell.updateColors()
        }
    }
    
    
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let tweet = content[indexPath.row] as? Tweet {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TweetCell") as! TweetCell
            cell.configure(tweet: tweet)
            return cell
        } else if let post = content[indexPath.row] as? RedditPost {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RedditPostCell") as! RedditPostCell
            cell.configure(post: post)
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
        } else if let post = content[indexPath.row] as? RedditPost {
            label.text = post.title
        }
        label.sizeToFit()
        
        return label.frame.height + 88
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
}

extension HomeViewController: AddTopicDelegate {
    func reloadView() {
        loadData()
    }

}
