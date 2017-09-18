//
//  LockerItemCollectionViewCell.swift
//  break
//
//  Created by Saagar Jha on 2/26/16.
//  Copyright © 2016 Saagar Jha. All rights reserved.
//

import UIKit

class LockerItemCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var typeImageView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var typeImageViewWidthConstraint: NSLayoutConstraint! {
		didSet {
			// Not sure why this is necessary, but adding it makes AutoLayout
			// stop complaining
			contentView.translatesAutoresizingMaskIntoConstraints = false
			nameLabel.preferredMaxLayoutWidth = typeImageViewWidthConstraint.constant
		}
	}
}
