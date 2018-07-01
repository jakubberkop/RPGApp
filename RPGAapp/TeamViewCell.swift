
//
//  TeamViewCell.swift
//  RPGAapp
//
//  Created by Jakub on 14.05.2018.
//  Copyright © 2018 Jakub. All rights reserved.
//

import Foundation
import UIKit
import Dwifft
import FontAwesome_swift

class TeamViewCell: UICollectionViewCell {
	
	@IBOutlet weak var abilityTable: UITableView!
	@IBOutlet weak var equipmentTable: UITableView!
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var raceLabel: UILabel!
	@IBOutlet weak var professionLabel: UILabel!
	
	@IBOutlet weak var moneyLabel: UILabel!
	@IBOutlet weak var moneyTextField: UITextField!
	
	@IBOutlet weak var abilityLabel: UILabel!
	@IBOutlet weak var equipmentLabel: UILabel!
	
	@IBOutlet weak var deleteButton: UIButton!
	@IBOutlet weak var editButton: UIButton!
	
	var abilityDiffCalculator: SingleSectionTableViewDiffCalculator<Ability>?
	var equipmentDiffCalculator: SingleSectionTableViewDiffCalculator<ItemHandler>?
	
	var character: Character!{
		didSet{
			abilities = character.abilities?.sortedArray(using: [.sortAbilityByName]) as? [Ability]
			items = character.equipment?.sortedArray(using: [.sortItemHandlerByName]) as? [ItemHandler]
			
			reloadLabels()
		}
	}
	
	var abilities: [Ability]!{
		didSet{
			abilityDiffCalculator?.rows = abilities
		}
	}
	
	var items: [ItemHandler]!{
		didSet{
			equipmentDiffCalculator?.rows = items
		}
	}
	
	override func awakeFromNib() {
		equipmentTable.dataSource = self
		abilityTable.dataSource = self
		
		equipmentDiffCalculator = SingleSectionTableViewDiffCalculator(tableView: equipmentTable)
		abilityDiffCalculator = SingleSectionTableViewDiffCalculator(tableView: abilityTable, initialRows: [], sectionIndex: 0)
		
		let iconSize: CGFloat = 25
		
		deleteButton.titleLabel?.font = UIFont.fontAwesome(ofSize: iconSize)
		deleteButton.setTitle(String.fontAwesomeIcon(name: .times), for: .normal)
		
		editButton.titleLabel?.font = UIFont.fontAwesome(ofSize: iconSize)
		editButton.setTitle(String.fontAwesomeIcon(name: .edit), for: .normal)
		
		abilityLabel.text = "Abilities"
		equipmentLabel.text = "Equipment"
		moneyLabel.text = "Money"
		
		
		NotificationCenter.default.addObserver(self, selector: #selector(modifiedAbility), name: .modifiedAbility, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(equipmentChanged), name: .equipmentChanged, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(reloadLabels) , name: .reloadTeam, object: nil)
		super.awakeFromNib()
	}
	
	func equipmentChanged(){
		if let newItems = character.equipment?.sortedArray(using: [.sortItemHandlerByName]) as? [ItemHandler] {
			items = newItems
		}
	}
	
	func reloadLabels(){
		if let name = character.name{
			nameLabel.text = "Name: \(name)"
		}
		
		if let race = character.race{
			raceLabel.text = "Race: \(race)"
		}
		
		if let profession = character.profession{
			professionLabel.text = "Profession \(profession)"
		}
		
		moneyTextField.text = showPrice(character.money)
	}
	
	@IBAction func removeCharacter() {
		let alert = UIAlertController(title: "Na pewno chcesz usunąć postać?", message: "", preferredStyle: .alert)
		
		let alertYes = UIAlertAction(title: "Tak", style: .destructive, handler: { (alert: UIAlertAction!) -> Void in
			let context = CoreDataStack.managedObjectContext
			
			let characterId = self.character.id
			context.delete(self.character)
			
			CoreDataStack.saveContext()
			
			self.equipmentTable.backgroundColor = .white
			self.abilityTable.backgroundColor = .white
			self.backgroundColor = .white
			
			NotificationCenter.default.post(name: .reloadTeam, object: nil)
			
			let action = NSMutableDictionary()
			let actionType = NSNumber(value: ActionType.removeCharacter.rawValue)
			
			action.setValue(actionType, forKey: "action")
			
			action.setValue(characterId, forKey: "characterId")
			
			PackageService.pack.send(action)
		})
		
		let alertNo = UIAlertAction(title: "Nie", style: .cancel, handler: { (alert: UIAlertAction!) -> Void in
			self.equipmentTable.backgroundColor = .red
			self.abilityTable.backgroundColor = .red
			self.backgroundColor = .red
		})
		
		alert.addAction(alertNo)
		alert.addAction(alertYes)
		
		next(UICollectionViewController.self)?.present(alert, animated: true, completion: nil)
	}

	@IBAction func editCharacter() {
		NotificationCenter.default.post(name: .modifyCharacter, object: character)
	}
	
	@IBAction func changedPlayerMoney(_ sender: UITextField) {
		guard let text = sender.text else { return }
		let value = convertCurrencyToValue(text)
		
		character.money = value
		
		CoreDataStack.saveContext()
	}
}

extension TeamViewCell: UITableViewDataSource, UITableViewDelegate{
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if tableView == abilityTable{
			return (abilityDiffCalculator?.rows.count)! + 1
		}else{
			return (equipmentDiffCalculator?.rows.count)!
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell") as? characterItemCell {
			let cellItem = equipmentDiffCalculator?.rows[indexPath.row]
			
			cell.itemHandlerDelegate = self
			
			cell.textLabel?.text = (cellItem?.item?.name)! + " " + String((cellItem?.count)!)
			
			cell.stepper.value = Double((cellItem?.count)!)
			cell.itemHandler = cellItem
			cell.character = character
			return cell
		}
			
		else{
			if indexPath.row == abilities.count{
				
				let cell = tableView.dequeueReusableCell(withIdentifier: "newAbilityCell") as? newAbilityCell
				
				cell?.newAbilityDelegate = self
				cell?.character = character
				
				return cell!
			}else{
				let cell = tableView.dequeueReusableCell(withIdentifier: "abilityCell") as? abilityCell
				
				cell?.abilityDelgate = self
				
				let ability = abilityDiffCalculator?.rows[indexPath.row]
				let abilityToShow = (ability?.name)! + ": " + String(describing: (ability?.value)!)
				
				cell?.ability = ability
				cell?.character = character
				cell?.textLabel?.text = abilityToShow
				
				return cell!
			}
		}
	}
}

extension TeamViewCell: AbilityCellDelegate{
	
	func modifiedAbility() {
		if let abs = character.abilities?.sortedArray(using: [.sortAbilityByName]) as? [Ability]{
			self.abilities = abs
		}
	}
}

extension TeamViewCell: CharacterItemCellDelegate{
	
	func modifiedItemHandler() {
		if let newItems = character.equipment?.sortedArray(using: [.sortItemHandlerByName]) as? [ItemHandler]{
			items = newItems
		}
	}
	
}
