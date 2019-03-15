/**
       This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
       Copyright © Adguard Software Limited. All rights reserved.
 
       Adguard for iOS is free software: you can redistribute it and/or modify
       it under the terms of the GNU General Public License as published by
       the Free Software Foundation, either version 3 of the License, or
       (at your option) any later version.
 
       Adguard for iOS is distributed in the hope that it will be useful,
       but WITHOUT ANY WARRANTY; without even the implied warranty of
       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
       GNU General Public License for more details.
 
       You should have received a copy of the GNU General Public License
       along with Adguard for iOS.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import UIKit

// MARK: custom views

class LangView: UIButton {
    var name: String?
}

class TagView: RoundRectButton {
    var name: String?
}

class TagCell: UICollectionViewCell {
    
    
    @IBOutlet weak var button: TagView!
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        var size = button.sizeThatFits(CGSize(width: 1000, height: button.frame.height))
        size.width = size.width + 6
        size.height = 22
        var newFrame = layoutAttributes.frame
        newFrame.size = size
        layoutAttributes.frame = newFrame
        
        return layoutAttributes
    }
    
}

class LangCell: UICollectionViewCell {
 
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var button: LangView!
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        let size = CGSize(width: 25, height: 22)
        var newFrame = layoutAttributes.frame
        newFrame.size = size
        layoutAttributes.frame = newFrame
        
        return layoutAttributes
    }
}

class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }
            
            layoutAttribute.frame.origin.x = leftMargin
            
            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY , maxY)
        }
        
        return attributes
    }
    
    
}

// MARK: - FiltersController -
class FiltersController: UITableViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIViewControllerTransitioningDelegate, CustomFilterInfoInfoDelegate, NewCustomFilterDetailsDelegate {
    
    var viewModel: FiltersViewModelProtocol?
    
    // MARK:  private properties
    
    var theme: ThemeServiceProtocol = ServiceLocator.shared.getService()!
    
    private let newFilterCellId = "newCustomFilterReuseID"
    private let filterCellId = "filterCellID"
    private let tagCellId = "tagCellId"
    private let langCellId = "langCellId"
    
    private var selectedIndex: Int?
    
    // MARK:  IB Outlets
    
    @IBOutlet var searchButton: UIBarButtonItem!
    @IBOutlet var cancelButton: UIBarButtonItem!
    @IBOutlet var searchView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet var headerView: UIView!
    @IBOutlet weak var headerLabel: ThemableLabel!
    @IBOutlet var themableLabels: [ThemableLabel]!
    
    
    
    // MARK: - ViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel?.filtersChangedCallback = { [weak self] in self?.tableView.reloadData() }
        viewModel?.searchChangedCallback = { [weak self] in self?.updateBarButtons() }
        tableView.rowHeight = UITableView.automaticDimension
        updateBarButtons()
        navigationItem.title = viewModel?.groupName
        if viewModel?.customGroup ?? false {
            tableView.tableHeaderView = headerView
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTheme()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddCustomFilterSegue" {
            
        }
    }
    
    // MARK: - TableView delegate methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel!.customGroup ? 2 : 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isAddFilter(section: section) {
            return 1
        }
        
        return viewModel?.filters.count ?? 0;
    }
    
    static var updated = false
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(isAddFilter(section: indexPath.section)) {
            let cell = tableView.dequeueReusableCell(withIdentifier: newFilterCellId)
            return cell!
        }
        else {
            let filter = viewModel?.filters[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: filterCellId) as! FilterCell
            cell.name.text = filter?.name ?? ""
            cell.filterDescription.text = filter?.desc ?? ""
            
            if let version = filter?.version {
                cell.version.text = String(format: ACLocalizedString("filter_version_format", nil), version)
            }

            cell.enableSwitch.tag  = indexPath.row
            cell.enableSwitch.isOn = filter?.enabled ?? false
            cell.homepageButton.tag = indexPath.row
            
            cell.collectionView.delegate = nil
            cell.collectionView.tag = indexPath.row
            cell.collectionView.delegate = self
            cell.collectionView.reloadData()
            
            cell.collectionView.layoutSubviews()
            cell.collectionHeightConstraint.constant = cell.collectionView.contentSize.height
            cell.collectionTopConstraint.constant = (cell.filterDescription.text?.count ?? 0) > 0 ? 19 : 0
            
            theme.setupLabels(cell.themableLabels)
            theme.setupTableCell(cell)
            theme.setupSwitch(cell.enableSwitch)
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(isAddFilter(section: indexPath.section)) {
            showAddFilterDialog()
        }
        else{
            if viewModel?.customGroup ?? false {
                selectedIndex = indexPath.row
                showCustomFilterInfoDialog()
            }
            else {
                let cell = tableView.cellForRow(at: indexPath) as! FilterCell
                cell.enableSwitch.setOn(!cell.enableSwitch.isOn, animated: true)
                toggleEnableSwitch(cell.enableSwitch)
            }
        }
    }
    
    // MARK: - CollectionView data source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let filterIndex = collectionView.tag
        let filter = viewModel?.filters[filterIndex]
        
        let tagsCount = filter?.tags?.count ?? 0
        let langsCount = filter?.langs?.count ?? 0
        return langsCount + tagsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let filterIndex = collectionView.tag
        if let filter = viewModel?.filters[filterIndex]{
            
            let langsCount = filter.langs?.count ?? 0
            
            if indexPath.row < langsCount {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: langCellId, for: indexPath) as! LangCell
                let lang = filter.langs![indexPath.row]
                cell.image.image = UIImage(named: lang.name)
                cell.image.alpha = lang.heighlighted ? 0.3 : 1.0
                cell.button.name = lang.name
                cell.button.removeTarget(self, action: #selector(langAction(_:)), for: .touchUpInside)
                cell.button.addTarget(self, action: #selector(langAction(_:)), for: .touchUpInside)
                
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: tagCellId, for: indexPath) as! TagCell
                let tag = filter.tags![indexPath.row - langsCount]
                cell.button.setTitle(tag.name, for: .normal)
                cell.button.alpha = tag.heighlighted ? 0.3 : 1.0
                cell.button.name = tag.name
                theme.setupTagButton(cell.button)
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    // MARK: - Actions
    
    @IBAction func toggleEnableSwitch(_ sender: UISwitch) {
        let row = sender.tag
        guard let filter = viewModel?.filters[row] else { return }
        viewModel?.set(filter: filter, enabled: sender.isOn) { (success) in }
    }
    
    @IBAction func showSiteAction(_ sender: UIButton) {
        let row = sender.tag
        let filter = viewModel?.filters[row]
        guard   let homepage = filter?.homepage,
                let url = URL(string: homepage) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @IBAction func searchAction(_ sender: Any) {
        
        viewModel?.searchFilter(query: "")
        self.updateBarButtons()
        searchBar.becomeFirstResponder()
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        tableView.tableHeaderView = nil
        viewModel?.cancelSearch()
        self.updateBarButtons()
    }
    
    @IBAction func tagAction(_ sender: TagView) {
        viewModel?.switchTag(name: sender.name ?? "")
    }
    
    @objc func langAction(_ sender: LangView) {
        viewModel?.switchTag(name: sender.name ?? "")
    }
    // MARK: - searchbar methods
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel?.searchFilter(query: searchBar.text ?? "")
    }
    
    // MARK: - Presentation delegate methods
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CustomAnimatedTransitioning()
    }
    
    // MARK: - FilterInfo delegate methods
    
    func deleteFilter(filter: Filter) {
        viewModel?.deleteCustomFilter(filter: filter, completion: { (succes) in
            self.tableView.reloadData()
        })
    }
    
    // MARK: - NewCustomFilter delegate
    func addCustomFilter(filter: AASCustomFilterParserResult, overwriteExisted: Bool) {
        viewModel?.addCustomFilter(filter: filter, overwriteExisted: overwriteExisted, completion: { (success) in
            self.tableView.reloadData()
        })
    }
    
    // MARK: - private methods
    
    private func updateTheme() {
        view.backgroundColor = theme.backgroundColor
        theme.setupNavigationBar(navigationController?.navigationBar)
        theme.setupTable(tableView)
        theme.setupSearchBar(searchBar)
        theme.setubBarButtonItem(searchButton)
        theme.setupLabels(themableLabels)
    }
    
    private func updateBarButtons() {
        if viewModel!.isSearchActive {
            navigationItem.rightBarButtonItems = [cancelButton]
            tableView.tableHeaderView = searchView
            searchBar.text = viewModel?.searchString
        }
        else {
            navigationItem.rightBarButtonItems = [searchButton]
            tableView.tableHeaderView = nil
            searchBar.text = viewModel?.searchString
        }
    }
    
    private func isAddFilter(section : Int) ->Bool {
        return viewModel!.customGroup && section == 0
    }
    
    private func showAddFilterDialog() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "NewCustomFilterInfoController") as? UINavigationController else { return }
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = self
        
        (controller.viewControllers.first as? AddCustomFilterController)?.delegate = self
        
        present(controller, animated: true, completion: nil)
    }
    
    private func showCustomFilterInfoDialog() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "CustomFilterInfoController") as? CustomFilterInfoInfoController else { return }
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = self
        controller.filter = viewModel?.filters[selectedIndex!]
        controller.delegate = self
        
        present(controller, animated: true, completion: nil)
    }
}