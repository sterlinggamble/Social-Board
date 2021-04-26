//
//  TweetCell.swift
//  Social Board
//
//  Created by Sterling Gamble on 4/10/21.
//

import UIKit
import AlamofireImage

class TweetCell: UITableViewCell {
    static let identifier = "TweetCell"
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = #colorLiteral(red: 0.2352941176, green: 0.2352941176, blue: 0.262745098, alpha: 0.6)
        return label
    }()
    
    private let backImageView: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0.8117647059, green: 0.8117647059, blue: 0.8117647059, alpha: 1)
        view.layer.masksToBounds = true
        return view
    }()
    
    private let textView: UITextView = {
        let textView = UITextView()
        return textView
    }()
    
    private let tweetContent: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let defaultImageURL = "https://abs.twimg.com/sticky/default_profile_images/default_profile_400x400.png"

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backImageView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(backImageView)
        contentView.addSubview(tweetContent)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        nameLabel.frame = CGRect(x: 69, y: 18, width: contentView.bounds.width-85, height: 20)
        usernameLabel.frame = CGRect(x: 69, y: 40, width: nameLabel.bounds.width, height: 18)
        backImageView.frame = CGRect(x: 16, y: 16, width: 43, height: 43)
        profileImageView.frame = backImageView.bounds
        backImageView.layer.cornerRadius = backImageView.bounds.width / 2
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        
        tweetContent.sizeToFit()
        tweetContent.frame = CGRect(x: 16, y: 72, width: contentView.bounds.width-32, height: tweetContent.bounds.height)
        
    }
    
    func configure(tweet: Tweet) {
        tweetContent.text = tweet.text
        nameLabel.text = tweet.user?.name
        usernameLabel.text = "@" + (tweet.user?.screen_name)!
        profileImageView.af.setImage(withURL: URL(string: tweet.user?.profile_image_url_https ?? defaultImageURL)!)
    }

}
