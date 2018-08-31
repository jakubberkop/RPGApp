//
//  TextureRequest.swift
//  RPGAapp
//
//  Created by Jakub on 31.08.2018.
//  Copyright © 2018 Jakub. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CoreData

struct TextureRequest: Action {
	
	var actionType: ActionType = ActionType.textureRequest
	var data: ActionData{
		get{
			let data = ActionData(dictionary: [
				"mapId"    : mapId,
				"entityId" : entityId
				])
			return data
		}
	}
	
	var sender: MCPeerID?
	
	var mapId: String
	var entityId: String
	
	var actionData: ActionData?
	
	init(actionData: ActionData, sender: MCPeerID){
		self.sender = sender
		
		self.mapId = actionData.value(forKeyPath: "mapId") as! String
		self.entityId = actionData.value(forKeyPath: "entityId") as! String
		
		self.actionData = actionData
	}
	
	init(mapId: String, entityId: String){
		self.mapId = mapId
		self.entityId = entityId
	}
	
	func execute(){
		var imageData: NSData?
		
		if let texture = Load.texture(with: entityId) {
			imageData = texture.data
		}else if let data = Load.map(withId: mapId)?.background?.data{
			imageData = data
		}
		
		guard let data = imageData else { return }		
		
		let action = TextureSend(imageData: data, mapId: mapId, entityId: entityId)
		PackageService.pack.send(action: action, to: sender!)
	}
}