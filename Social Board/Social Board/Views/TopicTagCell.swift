//
//  TopicTagCell.swift
//  Social Board
//
//  Created by Sterling Gamble on 4/10/21.
//

import UIKit

class TopicTagCell: UICollectionViewCell {
    static let identifier = "TopicTagCell"
    
    var isChosen: Bool = false
    
    let topicLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemBlue
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = #colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9607843137, alpha: 1)
        contentView.layer.cornerRadius = 14
        contentView.addSubview(topicLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        topicLabel.sizeToFit()
        topicLabel.frame = CGRect(x: 15, y: 7, width: topicLabel.bounds.width, height: topicLabel.bounds.height)
//        contentView.frame = CGRect(x: 0, y: 0, width: topicLabel.bounds.width+30, height: contentView.bounds.height)
//        topicLabel.frame
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func updateColors() {
        if isChosen {
            contentView.backgroundColor = #colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9607843137, alpha: 1)
            topicLabel.textColor = .systemBlue
            isChosen = false
        } else {
            contentView.backgroundColor = .systemBlue
            topicLabel.textColor = .white
            isChosen = true
        }
    }
    
}
