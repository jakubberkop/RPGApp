//
//  CatalogeFilterCell.swift
//  RPGAapp
//
//  Created by Jakub on 10.09.2018.
//  Copyright © 2018 Jakub. All rights reserved.
//

import Foundation
import UIKit

protocol CatalogeFilterCell {
	var filterItem: CatalogeFilterItem? { get set }
	func setup(using filterItem: CatalogeFilterItem) -> Void
}

class CatalogeFilterSlider: UITableViewCell, CatalogeFilterCell {
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var slider: UISlider!

	var filterItem: CatalogeFilterItem?
	
	func setup(using filterItem: CatalogeFilterItem){
		self.filterItem = filterItem
		
		self.nameLabel.text = "\(NSLocalizedString(filterItem.name, comment: "")) \(showPrice(filterItem.value))"
		
		let range = filterItem.range
		
		self.slider.minimumValue = Float(range.0)
		self.slider.maximumValue = Float(range.1)
		
		self.slider.setValue(Float(filterItem.value), animated: true)
	}
	
	@IBAction func valueChanged(){
		filterItem?.value = Double(slider.value)
		self.nameLabel.text = "\(NSLocalizedString((filterItem?.name)!, comment: "")) \(showPrice((filterItem?.value)!))"
	}
}

class CatalogeFilterStepper: UITableViewCell, CatalogeFilterCell {
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var stepper: UIStepper!
	
	var filterItem: CatalogeFilterItem?
	
	func setup(using filterItem: CatalogeFilterItem){
		self.filterItem = filterItem
		
		self.nameLabel.text = "\(NSLocalizedString(filterItem.name, comment: "")): \(rarityName[Int(filterItem.value) - 1])"
		
		let range = filterItem.range
		
		self.stepper.minimumValue = range.0
		self.stepper.maximumValue = range.1
		
		self.stepper.value = filterItem.value
	}
	
	@IBAction func valueChanged(){
		filterItem?.value = stepper.value
		self.nameLabel.text = "\(NSLocalizedString((filterItem?.name)!, comment: "")): \(rarityName[Int((filterItem?.value)!) - 1])"
	}
}
