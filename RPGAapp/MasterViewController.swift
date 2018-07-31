//
//  MasterViewController.swift
//  RPGAapp
//
//  Created by Jakub on 08.08.2017.
//  Copyright © 2017 Jakub. All rights reserved.
//

import UIKit
import Foundation

class MasterViewController: UITableViewController {
    
    var menuItems = [(NSLocalizedString("Cataloge"  ,comment: "") ,"showCatalogeView","showCatalogeDetailView"),
                     (NSLocalizedString("TeamView"  ,comment: "") ,"showTeamView", ""),
                     (NSLocalizedString("Map"       ,comment: "") ,"showMap", ""),
                     (NSLocalizedString("Draw Items",comment: "") ,"showRandomItemView","showRandomItemDetailView"),
					 (NSLocalizedString("Packages"  ,comment: "") ,"showPackageViewer",""),
					 (NSLocalizedString("Dice"      ,comment: "") ,"showRNG", ""),
					 (NSLocalizedString("Settings"  ,comment: "") ,"showSettings", "")
	]
    
    override func viewDidLoad() {
        splitViewController?.preferredDisplayMode = .allVisible
    }
     
    override func viewDidAppear(_ animated: Bool) {
        splitViewController?.preferredDisplayMode = .allVisible
    }
    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		let controller = (segue.destination as?UINavigationController)?.topViewController
		
		controller?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
		controller?.navigationItem.leftItemsSupplementBackButton = true
		
		if segue.identifier == "showMap" || segue.identifier == "showTeamView"{
			
            if UserDefaults.standard.bool(forKey: "Auto hide menu"){
                self.splitViewController?.preferredDisplayMode = .primaryHidden
            }
        }
		
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = menuItems[indexPath.row].0
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let segue = menuItems[indexPath.row]
		self.performSegue(withIdentifier: segue.1, sender: self)
		
		if segue.2 != ""{
			self.performSegue(withIdentifier: segue.2, sender: self)
		}
    }
}
