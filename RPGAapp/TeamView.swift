//
//  TeamView.swift
//  RPGAapp
//
//  Created by Jakub on 10.08.2017.
//  Copyright © 2017 Jakub. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class TeamView: UICollectionViewController {
    
    var team: [Character] = []
    
    override func viewDidLoad() {
        let addButton =  UIBarButtonItem.init(title: "Add", style: .plain, target: self, action: #selector(addCharacter(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTeam), name: .reloadTeam, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(addItem(_:)), name: .itemAddedToCharacter, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteItem(_:)), name: .itemDeletedFromCharacter, object: nil)
        reloadTeam()
        super.viewDidLoad()
    }
    
    func addItem(_ notification: NSNotification){
        let action = notification.object as! NSMutableDictionary
        let characterNumber = action.value(forKey: "characterNumber") as! Int
        let itemNumber = action.value(forKey: "itemNumber") as! Int
        let cell = self.collectionView?.cellForItem(at: IndexPath(item: characterNumber, section: 0)) as! TeamViewCell
        
        if (action.value(forKey: "createdNewHandler") as! Bool){
            let index = IndexPath(item: itemNumber, section: 0)
            cell.table.insertRows(at: [index], with: .left)
        }else{
            let index = IndexPath(item: itemNumber, section: 0)
            cell.table.reloadRows(at: [index], with: .fade)
        }
    }
    
    func deleteItem(_ notification: NSNotification){
        let action = notification.object as! NSMutableDictionary
        let characterNumber = action.value(forKey: "characterNumber") as! Int
        let itemNumber = action.value(forKey: "itemNumber") as! Int
        
        let cell = self.collectionView?.cellForItem(at: IndexPath(item: characterNumber, section: 0)) as! TeamViewCell
        
        let index = IndexPath(item: itemNumber, section: 0)
        cell.table.deleteRows(at: [index], with: .left)
    }
    
    func addCharacter(_ sender: Any){
        if !sessionIsActive(){
            return
        }
        let addCharControler = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "addCharacter")
        addCharControler.modalPresentationStyle = .formSheet
        self.present(addCharControler, animated: true, completion: nil)
    }
    
    func reloadTeam(){
        let session = getCurrentSession()
        
        team = session.characters?.sortedArray(using: [.sortCharacterById]) as! [Character]
        
        collectionView?.reloadData()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return team.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! TeamViewCell
        let person = team[indexPath.row]
        cell.nameLabel.text = person.name
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? TeamViewCell else { return }
        tableViewCell.setTableViewDataSourceDelegate(self, forRow: indexPath.row)
    }
}

extension TeamView: UITableViewDataSource, UITableViewDelegate{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell")
        if (cell != nil){
            return team[tableView.tag].equipment!.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell") {
            let equipment = team[tableView.tag].equipment!.sortedArray(using: [.sortItemHandlerByName]) as! [ItemHandler]
            cell.textLabel?.text = (equipment[indexPath.row].item?.name)!
            cell.detailTextLabel?.text = String(describing: equipment[indexPath.row].count)
            return cell
        }
        
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "abilityCell")
          //  let ablility = team[tableView.tag].abilites?[indexPath.row]
            //let abilityToShow = (ablility?.0)! + ": " + String(describing: (ablility?.1)!)
            //cell?.textLabel?.text = abilityToShow
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView.dequeueReusableCell(withIdentifier: "itemCell") != nil && sessionIsActive(show: false){
            return true
        }else{
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell")
        if cell != nil && editingStyle == .delete{
            let equipment = team[tableView.tag].equipment!.sortedArray(using: [.sortItemHandlerByName]) as! [ItemHandler]
            
            let action = NSMutableDictionary()
            let at = NSNumber(value: ActionType.itemDeletedFromCharacter.rawValue)
            action.setValue(at, forKey: "action")
            
            action.setValue(team[tableView.tag].id, forKey: "characterId")
            action.setValue(tableView.tag, forKey: "characterNumber")
            action.setValue(equipment[indexPath.row].item?.id, forKey: "itemId")
            action.setValue(indexPath.row, forKey: "itemNumber")
            
            team[tableView.tag].removeFromEquipment(equipment[indexPath.row])
            tableView.deleteRows(at: [indexPath], with: .automatic)
            CoreDataStack.saveContext()
            
            let packageService = (UIApplication.shared.delegate as! AppDelegate).pack
            packageService.send(action)
            return
        }
    }
}

class TeamViewCell: UICollectionViewCell {
    
    @IBOutlet var table: UITableView!
    
    @IBOutlet var ablilityTable: UITableView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    func setTableViewDataSourceDelegate<D: UITableViewDataSource & UITableViewDelegate>(_ dataSourceDelegate: D, forRow row: Int) {
        table.delegate = dataSourceDelegate
        table.dataSource = dataSourceDelegate
        table.tag = row
        ablilityTable.delegate = dataSourceDelegate
        ablilityTable.dataSource = dataSourceDelegate
        ablilityTable.tag = row
    }
}
extension Notification.Name{
    static let reloadTeam = Notification.Name("reloadTeam")
    static let reloadCharacterItems = Notification.Name("reloadCharacterItems")
    static let itemDeletedFromCharacter = Notification.Name("itemDeletedFromCharacter")
}
