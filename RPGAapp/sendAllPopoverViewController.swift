//
//  sendAllPopoverViewController.swift
//  RPGAapp
//
//  Created by Jakub on 30.08.2017.
//  Copyright © 2017 Jakub. All rights reserved.
//

import Foundation
import UIKit
import FontAwesome_swift
import CoreData

class sendAllPopover: UITableViewController, sendAllPopoverDelegate{
    
    override func viewWillAppear(_ animated: Bool) {
        let context = CoreDataStack.managedObjectContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Character")
        
        do {
            newTeam = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (newTeam.count > 0){
            return newTeam.count
        }
        else{
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sendAllPopoverCell") as! sendAllPopoverCell
        cell.cellDelegate = self
        if (newTeam.count > 0){
            cell.playerName.text = (newTeam[indexPath.row] as! Character).name
            cell.sendButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 20)
            cell.sendButton.setTitle(String.fontAwesomeIcon(name: .send), for: .normal)
        }
        else{
            cell.playerName.text = "Brak postaci"
            cell.sendButton.isHidden = true
        }
        return cell
    }
    
    func getCurrentCellIndexPath(_ sender: UIButton) -> IndexPath? {
        let buttonPosition = sender.convert(CGPoint.zero, to: tableView)
        if let indexPath: IndexPath = tableView.indexPathForRow(at: buttonPosition) {
            return indexPath
        }
        return nil
    }
    
    func sendItem(_ sender: UIButton) {
        let playerNum = getCurrentCellIndexPath(sender)?.row
        let senTo = newTeam[playerNum!] as! Character
        senTo.addToEquipment(NSOrderedSet(array: randomlySelected))
        CoreDataStack.saveContext()
        dismiss(animated: true, completion: nil)
    }
    
}

class sendAllPopoverCell: UITableViewCell{
    
    weak var cellDelegate: sendAllPopoverDelegate?
    
    @IBAction func sendButtonAction(_ sender: UIButton){
        cellDelegate?.sendItem(sender)
    }
    
    @IBOutlet var sendButton: UIButton!
    
    
    @IBOutlet var playerName: UILabel!
    
}


protocol sendAllPopoverDelegate: class{
    
    func sendItem(_ sender: UIButton)
    
}