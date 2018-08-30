//
//  ItemCharacterAdded.swift
//  RPGAapp
//
//  Created by Jakub on 30.08.2018.
//  Copyright © 2018 Jakub. All rights reserved.
//

import Foundation
import MultipeerConnectivity

struct ItemCharacterAdded: Action {
	
	var actionType: ActionType = ActionType.itemCharacterAdded
	var dictionary: ActionData{
		get{
			return ActionData()
		}
	}
	
	let from: MCPeerID
	
	let itemId: String?
	let itemCount: Int64?
	let itemsId: [String]?
	let itemsCount: [Int64]?
	
	let characterId: String?
	
	let actionData: ActionData
	
	init(actionData: ActionData, sender: MCPeerID) {
		from = sender
		
		itemId = actionData.value(forKey: "itemId") as? String
		itemCount = actionData.value(forKey: "itemCount") as? Int64
		
		itemsId = actionData.value(forKey: "itemsId") as? [String]
		itemsCount = actionData.value(forKey: "itemsCount") as? [Int64]
		
		characterId = actionData.value(forKey: "characterId") as? String
		
		self.actionData = actionData
	}
	
	func execute(){
		guard let characterId = characterId else { return }
		guard let character: Character = Load.character(with: characterId) else { return }
		
		var request: ItemRequest? = nil
		
		if let id = itemId{
			
			if let item = Load.item(with: id){
				
				if let count = itemCount{
					addToEquipment(item: item, to: character, count: count)
				}else{
					addToEquipment(item: item, to: character)
				}
				
			}else {
				request = ItemRequest(with: [id], sender: from, action: actionData)
			}
			
		}else if let count = itemsId?.count{
			var itemsToRequest: [String] = []
			
			for id in itemsId!{
				if Load.item(with: id) == nil{
					itemsToRequest.append(id)
				}
			}
			
			if itemsToRequest.count == 0{
				
				for itemNum in 0...count - 1{
					let id = itemsId![itemNum]
					
					if let item = Load.item(with: id){
						addToEquipment(item: item, to: character, count: (itemsCount?[itemNum])!)
					}
				}
				
			}else{
				request = ItemRequest(with: itemsToRequest, sender: from, action: actionData)
			}
		}
		
		if let req = request {
			ItemRequester.rq.request(req)
		}
		
		CoreDataStack.saveContext()
		
		NotificationCenter.default.post(name: .equipmentChanged, object: nil)
	}
}