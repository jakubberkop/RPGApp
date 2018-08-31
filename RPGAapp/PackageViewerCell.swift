//
//  PackageViewerCell.swift
//  RPGAapp
//
//  Created by Jakub on 25.06.2018.
//  Copyright © 2018 Jakub. All rights reserved.
//

import Foundation
import UIKit
import Dwifft

class PackageViewerCell: UITableViewCell{
	
	@IBOutlet var itemTable: UITableView!
	
	@IBOutlet var nameLabel: UILabel!
	@IBOutlet var sendButton: UIButton!
	
	var package: Package?{
		didSet{
			guard let it = package?.items?.sortedArray(using: [.sortItemHandlerByName]) as? [ItemHandler] else {
				items = []
				itemTable.reloadData()
				return
			}
			items = it
			
			nameLabel.text = package?.name
			
			sendButton.titleLabel?.font = UIFont.fontAwesome(ofSize: iconSize)
			sendButton.setTitle(String.fontAwesomeIcon(name: .send), for: .normal)
		}
	}
	
	var items: [ItemHandler] = []{
		didSet{
			diffCalculator?.rows = items
		}
	}
	
	var diffCalculator: SingleSectionTableViewDiffCalculator<ItemHandler>?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		itemTable.dataSource = self
		
		NotificationCenter.default.addObserver(self, selector: #selector(reloadPackage), name: .addedItemToPackage, object: nil)
		
		let removeItem = UILongPressGestureRecognizer(target: self, action: #selector(removeItemLongPress))
		removeItem.delegate = self
		self.itemTable.addGestureRecognizer(removeItem)
		
		diffCalculator = SingleSectionTableViewDiffCalculator(tableView: itemTable)		
	}
	
	override func prepareForReuse() {
		package = nil		
		super.prepareForReuse()
	}
	
	
	func reloadPackage(){
		guard let items = package?.items?.sortedArray(using: [.sortItemHandlerByName]) as? [ItemHandler] else { return }
		self.items = items
	}
	
	@IBAction func sendItems(_ sender: UIButton) {
		
		let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sendPop")
		
		popController.modalPresentationStyle = UIModalPresentationStyle.popover
		
		popController.popoverPresentationController?.sourceView = sender
		
		(popController as! sendPopover).itemHandlers = items
		
		let topViewController = UIApplication.topViewController()
		
		topViewController?.present(popController, animated: true, completion: nil)
	}
	
	var removeItemCancelled: Bool = false
	var lastCellIndex: IndexPath? = nil
	
	func removeItemLongPress(_ sender: UILongPressGestureRecognizer) {
		let touchPoint = sender.location(in: self.contentView)
		
		guard let indexPath = itemTable.indexPathForRow(at: touchPoint) else {
			guard let index = lastCellIndex else { return }
			guard let cell = itemTable.cellForRow(at: index) else { return }
			
			UIView.animate(withDuration: 0.2, animations: {
				cell.backgroundColor = .white
			})
			
			return
		}
		
		lastCellIndex = indexPath
		
		guard let cell = itemTable.cellForRow(at: indexPath) else { return }
		
		switch sender.state {
		case .changed:
			removeItemCancelled = true
			break
			
		case .began:
			removeItemCancelled = false
			
			UIView.animate(withDuration: sender.minimumPressDuration, animations: {
				cell.backgroundColor = .red
			})
			break
			
		case .ended:
			guard !removeItemCancelled else {
				UIView.animate(withDuration: 0.2, animations: {
					cell.backgroundColor = .white
				})
				
				break
			}
			let context = CoreDataStack.managedObjectContext
			
			let item = items[indexPath.row]
			let itemId = item.item?.id
			
			package?.removeFromItems(item)
			
			context.delete(item)
			CoreDataStack.saveContext()
			
			reloadPackage()
			
			cell.backgroundColor = .white
			
			let action = ItemDeletedPackage(package: package!, itemId: itemId!)
			PackageService.pack.send(action: action)
			
			removeItemCancelled	= false
			
		case .cancelled:
			removeItemCancelled = true
			
		default:
			UIView.animate(withDuration: 0.2, animations: {
				cell.backgroundColor = .white
			})
		}
	}
}

extension PackageViewerCell: UITableViewDataSource{
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return items.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "PackageViewerItemCell")!
		
		let itemHandler = items[indexPath.row]
		
		if let name = itemHandler.item?.name{
			cell.textLabel?.text = "\(name) \(itemHandler.count)"
		}else{
			cell.textLabel?.text = ""
		}

		cell.selectionStyle = .none
		
		return cell
	}
}
