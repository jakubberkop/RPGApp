//
//  CatalogeDetailViewController.swift
//  RPGAapp
//
//  Created by Jakub on 09.08.2017.
//  Copyright © 2017 Jakub. All rights reserved.
//

import Foundation
import UIKit
import FontAwesome_swift
import CoreData
import Dwifft
import Former

class catalogeDetail: UIViewController, UITableViewDataSource, UITableViewDelegate, catalogeDetailCellDelegate, UIPopoverPresentationControllerDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    
    var filter: [String : Double?] = [:]

	var sortModel: [(String,Bool,NSSortDescriptor)] = []
	
	var searchModel: [(String, Bool)] = []
	
	var lastSearchString: String = ""
	
    var expandedCell: IndexPath? = nil
    
    let iconSize: CGFloat = 20
    
    @IBOutlet weak var catalogTable: UITableView!
    
    var diffCalculator: TableViewDiffCalculator<SubCategory,Item>?
    
    var items: SectionedValues<SubCategory,Item> = SectionedValues(Load.subCategoriesForCatalog()){
        didSet{
            self.diffCalculator?.sectionedValues = items
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        
        self.diffCalculator = TableViewDiffCalculator(tableView: self.tableView, initialSectionedValues: self.items)
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create item", style: .plain, target: self, action: #selector(newItemForm))
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: .reload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(goToSection(_:)), name: .goToSectionCataloge, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadFilter(_:)), name: .reloadCatalogeFilter, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(searchCataloge(_:)), name: .searchCataloge, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(searchModelChanged(_:)), name: .searchCatalogeModelChanged, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(sortModelChange(_:)), name: .sortModelChanged, object: nil)
		
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        deleteTempSubCategory()
        super.viewWillDisappear(animated)
    }
    
    func dismissKeyboard(){
        NotificationCenter.default.post(name: .dismissKeyboard, object: nil)
    }
	
	func newItemForm() {
		let form = NewItemForm()
		
		form.modalPresentationStyle = .formSheet
		
		self.present(form, animated: true, completion: nil)
	}
	
	func sortModelChange(_ notification: Notification){
		if let newSortModel = notification.object as? [(String,Bool,NSSortDescriptor)]{
			sortModel = newSortModel
			
			items = RPGAapp.searchCataloge(searchWith: lastSearchString, using: searchModel, sortBy: sortModel)
		}
	}
	
	func searchModelChanged(_ notification: Notification){
		if let newSearchModel = notification.object as? [(String, Bool)]{
			searchModel = newSearchModel
			items = RPGAapp.searchCataloge(searchWith: lastSearchString, using: searchModel,sortBy: sortModel)
		}
	}
	
	func searchCataloge(_ notification: Notification){
		if let data = (notification.object as? (String,[(String, Bool)],[(String,Bool,NSSortDescriptor)])){
			let enteredString = data.0
			lastSearchString = enteredString
			
			let newSearchModel = data.1
			searchModel = newSearchModel
			
			let newSortModel = data.2
			sortModel = newSortModel
		
			items = RPGAapp.searchCataloge(searchWith: enteredString, using: searchModel,sortBy: sortModel)
		}
    }
    
    func reloadFilter(_ notification: Notification){
        if let newFilter = notification.object as? Dictionary<String, Double?>{
            DispatchQueue.global(qos: .default).sync {
                self.filter = newFilter
                var newSubCategoriesList: [(SubCategory,[Item])] = []
                for sub in Load.subCategoriesForCatalog(){
                    let filteredList = self.filterItemList(sub.1)
                    newSubCategoriesList.append((sub.0),filteredList)
                }
                
                DispatchQueue.main.async {
                    self.items = SectionedValues(newSubCategoriesList)
                }
            }
        }
    }
    
    func filterItemList( _ items: [Item]) -> [Item]{
        let minRarity = filter["minRarity"]
        let maxRarity = filter["maxRarity"]
        let minPrice = filter["minPrice"]
        let maxPrice = filter["maxPrice"]
        
        let itemsToRet = items.filter({
            $0.rarity >= Int16(minRarity!!) &&
                $0.rarity <= Int16(maxRarity!!) &&
                $0.price >= minPrice!! &&
                $0.price <= maxPrice!!
        })
        return itemsToRet
    }
    
    func reloadTableData(_ notification: Notification) {
        tableView.reloadData()
    }
    
    func goToSection(_ notification: Notification) {
        guard items.sectionsAndValues.count > 1  else {
            return
        }
        
        let subCategoryNumber = notification.object as! Int
        
        if tableView(self.tableView, numberOfRowsInSection: subCategoryNumber) != 0{
            let toGo = IndexPath(row: 0, section: subCategoryNumber)
            tableView.scrollToRow(at: toGo, at: .top, animated: true)
            
        }else if subCategoryNumber != 0
            && tableView(self.tableView, numberOfRowsInSection: subCategoryNumber - 1) != 0{
            let toGo = IndexPath(row: 0, section: subCategoryNumber - 1)
            tableView.scrollToRow(at: toGo, at: .top, animated: true)
            
        }else if subCategoryNumber != numberOfSections(in: self.tableView)
            && tableView(self.tableView, numberOfRowsInSection: subCategoryNumber + 1) != 0 {
            let toGo = IndexPath(row: 0, section: subCategoryNumber + 1)
            tableView.scrollToRow(at: toGo, at: .top, animated: true)
        }
    }
    
    //MARK: Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.diffCalculator?.numberOfSections() ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.diffCalculator?.numberOfObjects(inSection: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = ""
        
        if let subCategory = self.diffCalculator?.value(forSection: section).name{
            if let category = self.diffCalculator?.value(forSection: section).category?.name{
                title = category.capitalized + " " + subCategory.lowercased()
            }else{
                title = subCategory.capitalized
            }
        }
        return title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellItem = (self.diffCalculator?.value(atIndexPath: indexPath))!
        if expandedCell == indexPath{
            let cell = tableView.dequeueReusableCell(withIdentifier: "catalogDetailExpandedCell") as! catalogeDetailExpandedCell
            cell.item = cellItem
            cell.loadAtributes()
            
            cell.cellDelegate = self
            
            cell.nameLabel.text = cellItem.name
            cell.priceLabel.text = String(cellItem.price) + "PLN"
            
            cell.sendButton.titleLabel?.font = UIFont.fontAwesome(ofSize: iconSize)
            cell.sendButton.setTitle(String.fontAwesomeIcon(name: .send), for: .normal)
            
            cell.infoButton.titleLabel?.font = UIFont.fontAwesome(ofSize: iconSize)
            cell.infoButton.setTitle(String.fontAwesomeIcon(name: .info), for: .normal)
            
            cell.editButton.titleLabel?.font = UIFont.fontAwesome(ofSize: iconSize)
            cell.editButton.setTitle(String.fontAwesomeIcon(name: .edit), for: .normal)
            
            cell.packageButton.titleLabel?.font = UIFont.fontAwesome(ofSize: iconSize)
            cell.packageButton.setTitle(String.fontAwesomeIcon(name: .cube), for: .normal)
            
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "catalogeDetailCell") as! catalogeDetailCell
            
            cell.cellDelegate = self
            cell.item = cellItem
            
            cell.nameLabel.text = cellItem.name
            
            var priceToShow = String()
            
            if  cellItem.price != nil  {
                if UserDefaults.standard.bool(forKey: "Show price"){
                    //priceToShow = changeCurrency(price: cellItem.price, currency: listOfItems.currency)
                    priceToShow = String(cellItem.price) + "PLN"
                }
                else{
                    priceToShow = String(cellItem.price) + "PLN"
                }
            }
            else {
                priceToShow = "Brak ceny"
                print(cellItem.price)
            }
            
            cell.priceLabel.text = priceToShow
            
            cell.sendButton.titleLabel?.font = UIFont.fontAwesome(ofSize: iconSize)
            cell.sendButton.setTitle(String.fontAwesomeIcon(name: .send), for: .normal)
            
            cell.infoButton.titleLabel?.font = UIFont.fontAwesome(ofSize: iconSize)
            cell.infoButton.setTitle(String.fontAwesomeIcon(name: .info), for: .normal)
            
            cell.editButton.titleLabel?.font = UIFont.fontAwesome(ofSize: iconSize)
            cell.editButton.setTitle(String.fontAwesomeIcon(name: .edit), for: .normal)
            
            cell.packageButton.titleLabel?.font = UIFont.fontAwesome(ofSize: iconSize)
            cell.packageButton.setTitle(String.fontAwesomeIcon(name: .cube), for: .normal)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if expandedCell != nil && indexPath == expandedCell{
            return 150
        }else{
            return  44
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath != expandedCell else {
            return
        }
        
        if expandedCell != nil{
            let tmpIndex = expandedCell
            expandedCell = nil
            tableView.reloadRows(at: [tmpIndex!], with: .automatic)
        }
        expandedCell = indexPath
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
        
        if tableView.cellForRow(at: indexPath) == tableView.visibleCells.first {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }else if tableView.cellForRow(at: indexPath) == tableView.visibleCells.last {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    
    //MARK: Cell Delegates
    
    func addToPackageButton(_ sender: UIButton){
        if !sessionIsActive(){
            return
        }
        let indexPath = getCurrentCellIndexPath(sender, tableView: self.tableView)
        
        let cellItem = (self.diffCalculator?.value(atIndexPath: indexPath!))
        
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "addToPackage")
        
        popController.modalPresentationStyle = .popover
        
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = sender
        
        (popController as! addToPackage).item = cellItem
        
        self.present(popController, animated: true, completion: nil)
    }
    
    func editItemButton(_ sender: UIButton){
        if !sessionIsActive(){
            return
        }
    }
    
    func showInfoButton(_ sender: UIButton){
        let indexPath = getCurrentCellIndexPath(sender, tableView: self.tableView)
        
        let cellItem = (self.diffCalculator?.value(atIndexPath: indexPath!))
        
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "showInfoPop")
        
        popController.modalPresentationStyle = .popover
        
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = sender
        
        (popController as! showItemInfoPopover).item = cellItem
        
        self.present(popController, animated: true, completion: nil)
    }
    
    func sendItemButton(_ sender: UIButton){
        if !sessionIsActive(){
            return
        }
        let indexPath = getCurrentCellIndexPath(sender, tableView: self.tableView)
        
        let cellItem = (self.diffCalculator?.value(atIndexPath: indexPath!))
        
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sendPop")
        
        popController.modalPresentationStyle = .popover
        
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = sender
        
        (popController as! sendPopover).item = cellItem

        self.present(popController, animated: true, completion: nil)
    }
}

class catalogeDetailCell: UITableViewCell{
    
    var item: Item? = nil
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet var packageButton: UIButton!
    
    @IBOutlet var editButton: UIButton!
    
    @IBOutlet var infoButton: UIButton!
    
    @IBOutlet var sendButton: UIButton!
    
    weak var cellDelegate: catalogeDetailCellDelegate?
    
    @IBAction func addToPackageButton(_ sender: UIButton) {
        cellDelegate?.addToPackageButton(sender)
    }
    
    @IBAction func editItemButton(_ sender: UIButton) {
        cellDelegate?.editItemButton(sender)
    }
    
    @IBAction func showInfoButton(_ sender: UIButton) {
        cellDelegate?.showInfoButton(sender)
    }
    
    @IBAction func sendItemButton(_ sender: UIButton) {
        cellDelegate?.sendItemButton(sender)
    }

}

class catalogeDetailExpandedCell: UITableViewCell, UITableViewDataSource, UITableViewDelegate{
    
    var item: Item? = nil
    var atributes: [ItemAtribute]!
    var atributeHandler: ItemAtributeHandler!
   
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet var packageButton: UIButton!
    @IBOutlet var editButton: UIButton!
    @IBOutlet var infoButton: UIButton!
    @IBOutlet var sendButton: UIButton!
    
    @IBOutlet weak var atributeTable: UITableView!
    
    weak var cellDelegate: catalogeDetailCellDelegate?
    
    @IBAction func addToPackageButton(_ sender: UIButton) {
        cellDelegate?.addToPackageButton(sender)
    }
    
    @IBAction func editItemButton(_ sender: UIButton) {
        cellDelegate?.editItemButton(sender)
    }
    
    @IBAction func showInfoButton(_ sender: UIButton) {
        cellDelegate?.showInfoButton(sender)
    }
    
    @IBAction func sendItemButton(_ sender: UIButton) {
        cellDelegate?.sendItemButton(sender)
    }
    
    func loadAtributes(){
        atributeTable.dataSource = self
        atributeTable.delegate = self
        atributeHandler = NSEntityDescription.insertNewObject(forEntityName: String(describing: ItemAtributeHandler.self), into: CoreDataStack.managedObjectContext) as! ItemAtributeHandler
        
        let sortAtributes = NSSortDescriptor(key: #keyPath(ItemAtribute.name), ascending: true)
        atributes = item?.itemAtribute?.sortedArray(using: [sortAtributes]) as! [ItemAtribute]
        
        if atributes != nil{
            for cellNum in 0...tableView(atributeTable, numberOfRowsInSection: 0){
                let cell = atributeTable.cellForRow(at: IndexPath(row: cellNum, section: 0))
                cell?.prepareForReuse()
                cell?.setSelected(false, animated: true)
                cell?.accessoryType = .none
            }
        }
        atributeTable.reloadData()
    }
    
    //MARK: CatalogExpandedAtributeTable
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard item != nil else {
            return 0
        }
        if(atributes.count == 0){
            return 1
        }else{
            return atributes.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AtributeCell")
        if atributes.count == 0{
            cell?.textLabel?.text = "Brak atrybutów"
            return cell!
        }
        cell?.textLabel?.text = atributes[indexPath.row].name
        cell?.selectionStyle = .none
        if (atributeHandler.itemAtributes?.contains(atributes[indexPath.row]))!{
            cell?.accessoryType = .checkmark
        }
        else{
            cell?.accessoryType = .none
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard atributes.count != 0 else{
            return
        }
        let newAtribute = atributes[indexPath.row]
        atributeHandler.addToItemAtributes(newAtribute)
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard atributes.count != 0 else{
            return
        }
        let atribute = atributes[indexPath.row]
        atributeHandler.removeFromItemAtributes(atribute)
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .none
    }
}

protocol catalogeDetailCellDelegate: class{
    
    func addToPackageButton(_ sender: UIButton)
    
    func editItemButton(_ sender: UIButton)
    
    func showInfoButton(_ sender: UIButton)
    
    func sendItemButton(_ sender: UIButton)
    
}
