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

import UIKit
import SafariAdGuardSDK

final class ComplexProtectionController: UITableViewController {
    
    // MARK: - Title Outlets
    
    @IBOutlet weak var titlImageView: UIImageView!

    // MARK: - Safari protection outlets
    
    @IBOutlet weak var safariIcon: UIImageView!
    @IBOutlet weak var freeLabel: EdgeInsetLabel! {
        didSet{
            freeLabel.text = freeLabel.text?.uppercased()
            
            freeLabel.layer.borderColor = UIColor(hexString: "#5a9c69").cgColor
            freeLabel.layer.borderWidth = 1.0
            
            freeLabel.clipsToBounds = true
            freeLabel.layer.cornerRadius = 4.0
        }
    }
    @IBOutlet weak var safariProtectionLabel: ThemableLabel!
    @IBOutlet weak var safariDescriptionLabel: ThemableLabel!
    @IBOutlet weak var safariProtectionSwitch: UISwitch!
    
    @IBOutlet weak var freeLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var freeLabelSpacing: NSLayoutConstraint!
    
    
    // MARK: - System protection outlets
    
    @IBOutlet weak var systemIcon: UIImageView!
    @IBOutlet weak var premiumLabel: EdgeInsetLabel! {
        didSet{
            premiumLabel.text = premiumLabel.text?.uppercased()
            premiumLabel.clipsToBounds = true
            premiumLabel.layer.cornerRadius = 4.0
        }
    }
    
    @IBOutlet weak var systemProtectionSwitch: UISwitch!
    
    @IBOutlet weak var premiumLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var premiumLabelSpacing: NSLayoutConstraint!
    
    
    //MARK: - Advanced protection outlets
    @IBOutlet weak var advancedProtectionIcon: UIImageView!
    @IBOutlet weak var advancedProtectionLabel: EdgeInsetLabel! {
        didSet {
            advancedProtectionLabel.text = advancedProtectionLabel.text?.uppercased()
            advancedProtectionLabel.clipsToBounds = true
            advancedProtectionLabel.layer.cornerRadius = 4.0
        }
    }
    @IBOutlet weak var advancedProtectionSwitch: UISwitch!
    
    @IBOutlet weak var premiumAdvancedProtectionLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var premiumAdvancedProtectionLabelSpacing: NSLayoutConstraint!
    
    
    // MARK: - AdGuard VPN upsell outlets
    
    @IBOutlet weak var adguardVpnIcon: UIImageView!
    @IBOutlet weak var notInstalledLabel: EdgeInsetLabel! {
        didSet{
            notInstalledLabel.text = notInstalledLabel.text?.uppercased()
            
            notInstalledLabel.layer.borderColor = UIColor.AdGuardColor.lightGray4.cgColor
            notInstalledLabel.layer.borderWidth = 1.0
            
            notInstalledLabel.clipsToBounds = true
            notInstalledLabel.layer.cornerRadius = 4.0
        }
    }
    
    @IBOutlet weak var notInstalledLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var notInstalledLabelSpacing: NSLayoutConstraint!
    
    @IBOutlet var themableLabels: [ThemableLabel]!
    
    
    // MARK: - Variables
    
    // Services
    private let theme: ThemeServiceProtocol = ServiceLocator.shared.getService()!
    private let configuration: ConfigurationServiceProtocol = ServiceLocator.shared.getService()!
    private let resources: AESharedResourcesProtocol = ServiceLocator.shared.getService()!
    private let complexProtection: ComplexProtectionServiceProtocol = ServiceLocator.shared.getService()!
    private let nativeDnsManager: NativeDnsSettingsManagerProtocol = ServiceLocator.shared.getService()!
    private let safariProtection: SafariProtectionProtocol = ServiceLocator.shared.getService()!
    
    // Observers
    private var vpnChangeObservation: NotificationToken?
    private var proObservation: NotificationToken?
    private var appWillEnterForegroundObservation: NotificationToken?
    
    private var proStatus: Bool {
        return configuration.proStatus
    }
    
    private let enabledColor = UIColor.AdGuardColor.lightGreen1
    private let disabledColor = UIColor.AdGuardColor.lightGray5
    
    private let titleSection = 0
    private let protectionSection = 1
    
    private let safariProtectionCell = 0
    private let systemProtectionCell = 1
    private let advancedYouTubeAdsBlockingCell = 2
    private let advancedProtectionCell = 3
    private let adguardVpnCell = 4

    private let showTrackingProtectionSegue = "showTrackingProtection"
    private let showLicenseSegue = "ShowLicenseSegueId"
    
    // MARK: - View Controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        updateTheme()

        addObservers()
        updateAdGuardVpnStatus()
        
        resources.sharedDefaults().addObserver(self, forKeyPath: SafariProtectionState, options: .new, context: nil)
        
        freeLabel.text = freeLabel.text?.uppercased()
        premiumLabel.text = premiumLabel.text?.uppercased()
        advancedProtectionLabel.text = advancedProtectionLabel.text?.uppercased()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSafariProtectionInfo()
        updateAdvancedProtectionInfo()
        observeProStatus()
        updateVpnInfo()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        observeProStatus()
    }
    
    deinit {
        if isViewLoaded {
            resources.sharedDefaults().removeObserver(self, forKeyPath: SafariProtectionState)
        }
    }
    
    // MARK: - Actions

    @IBAction func safariProtectionChanged(_ sender: UISwitch) {
        let enabled = sender.isOn
        complexProtection.switchSafariProtection(state: enabled, for: self) { _ in }
        updateSafariProtectionInfo()
    }
    
    @IBAction func systemProtectionChanged(_ sender: UISwitch) {
        if resources.dnsImplementation == .native {
            if #available(iOS 14.0, *), complexProtection.systemProtectionEnabled {
                nativeDnsManager.removeDnsConfig { error in
                    DDLogError("Error removing dns manager: \(error.debugDescription)")
                    DispatchQueue.main.async { [weak self] in
                        sender.isOn = self?.complexProtection.systemProtectionEnabled ?? false
                    }
                }
            } else if #available(iOS 14.0, *) {
                sender.isOn = complexProtection.systemProtectionEnabled
                nativeDnsManager.saveDnsConfig { error in
                    if let error = error {
                        DDLogError("Received error when turning system protection on; Error: \(error.localizedDescription)")
                    }
                    DispatchQueue.main.async {
                        AppDelegate.shared.presentHowToSetupController()
                    }
                }
            }
            return
        }
        
        let enabled = sender.isOn
        if enabled && !configuration.proStatus {
            performSegue(withIdentifier: self.showLicenseSegue, sender: self)
            return
        }
        
        complexProtection.switchSystemProtection(state: enabled, for: self) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.systemProtectionSwitch.isOn = self.complexProtection.systemProtectionEnabled
                self.systemIcon.tintColor = self.complexProtection.systemProtectionEnabled ? self.enabledColor : self.disabledColor
                
                if error != nil {
                    self.performSegue(withIdentifier: self.showTrackingProtectionSegue, sender: self)
                }
            }
        }
        updateVpnInfo()
    }
    
    @IBAction func advancedProtectionChanged(_ sender: UISwitch) {
        if sender.isOn && !configuration.proStatus {
            performSegue(withIdentifier: self.showLicenseSegue, sender: self)
            return
        }
        
        let newAdvancedProtectionState = sender.isOn
        configuration.isAdvancedProtectionEnabled = newAdvancedProtectionState
        safariProtection.update(advancedProtectionEnabled: newAdvancedProtectionState, onCbReloaded: nil)
        updateAdvancedProtectionInfo()
    }
    
    // MARK: - Table view delegates and dataSource methods
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        theme.setupTableCell(cell)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == protectionSection, indexPath.row == adguardVpnCell {
            if UIApplication.adGuardVpnIsInstalled {
                UIApplication.openAdGuardVpnAppIfInstalled()
            } else {
                presentUpsellScreen()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.section == protectionSection else { return }
        
        if #available(iOS 15, *) {
            if indexPath.row == advancedYouTubeAdsBlockingCell {
                cell.isHidden = true
            }
        } else {
            if indexPath.row == advancedProtectionCell {
                cell.isHidden = true
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section == protectionSection else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
        
        if #available(iOS 15, *) {
            if indexPath.row == advancedYouTubeAdsBlockingCell {
                return 0
            }
        } else {
            if indexPath.row == advancedProtectionCell {
                return 0
            }
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    
    
    // MARK: - Observer
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == SafariProtectionState {
            updateSafariProtectionInfo()
        }
    }
    
    // MARK: - Private methods
    
    private func addObservers() {
        
        proObservation = NotificationCenter.default.observe(name: .proStatusChanged, object: nil, queue: .main) { [weak self] _ in
            self?.observeProStatus()
        }
        
        vpnChangeObservation = NotificationCenter.default.observe(name: ComplexProtectionService.systemProtectionChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateVpnInfo()
        }
        
        appWillEnterForegroundObservation = NotificationCenter.default.observe(name: UIApplication.willEnterForegroundNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.updateAdGuardVpnStatus()
        })
    }
    
    /**
     Called when pro status is changed
     */
    private func observeProStatus(){
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            
            let isBigScreen = self.traitCollection.verticalSizeClass == .regular && self.traitCollection.horizontalSizeClass == .regular
            let height: CGFloat = isBigScreen ? 26.0 : 18.0
            
            self.freeLabelHeight.constant = self.proStatus ? 0.0 : height
            self.premiumLabelHeight.constant = self.proStatus ? 0.0 : height
            self.premiumAdvancedProtectionLabelHeight.constant = self.proStatus ? 0.0 : height
            
            self.freeLabelSpacing.constant = self.proStatus ? 0.0 : 12.0
            self.premiumLabelSpacing.constant = self.proStatus ? 0.0 : 12.0
            self.premiumAdvancedProtectionLabelSpacing.constant = self.proStatus ? 0.0 : 12.0
            
            self.tableView.reloadData()
        }
    }
    
    /**
     Called when vpn configuration changes
     */
    private func updateVpnInfo(){
        let enabled = complexProtection.systemProtectionEnabled
        systemProtectionSwitch.isOn = enabled
        systemIcon.tintColor = enabled ? enabledColor : disabledColor
        tableView.reloadData()
    }
    
    private func updateSafariProtectionInfo(){
        DispatchQueue.asyncSafeMain { [weak self] in
            let protectionEnabled = self?.complexProtection.safariProtectionEnabled ?? false
            self?.safariProtectionSwitch.isOn = protectionEnabled
            self?.safariIcon.tintColor = protectionEnabled ? self?.enabledColor : self?.disabledColor
        }
    }
    
    private func updateAdvancedProtectionInfo() {
        let protectionEnabled = configuration.isAdvancedProtectionEnabled
        advancedProtectionSwitch.isOn = protectionEnabled
        advancedProtectionIcon.tintColor = protectionEnabled ? enabledColor : disabledColor
    }
    
    private func updateAdGuardVpnStatus() {
        let installed = UIApplication.adGuardVpnIsInstalled
        adguardVpnIcon.tintColor = installed ? enabledColor : disabledColor
        
        let isBigScreen = self.traitCollection.verticalSizeClass == .regular && self.traitCollection.horizontalSizeClass == .regular
        let height: CGFloat = isBigScreen ? 26.0 : 18.0
        
        notInstalledLabelHeight.constant = installed ? 0.0 : height
        notInstalledLabelSpacing.constant = installed ? 0.0 : 12.0
        
        tableView.reloadData()
    }
}

extension ComplexProtectionController: ThemableProtocol {
    func updateTheme(){
        view.backgroundColor = theme.backgroundColor
        premiumLabel.backgroundColor = theme.invertedBackgroundColor
        premiumLabel.textColor = theme.backgroundColor
        
        advancedProtectionLabel.backgroundColor = theme.invertedBackgroundColor
        advancedProtectionLabel.textColor = theme.backgroundColor

        theme.setupSwitch(safariProtectionSwitch)
        theme.setupSwitch(systemProtectionSwitch)
        theme.setupSwitch(advancedProtectionSwitch)
        theme.setupTable(tableView)
        theme.setupNavigationBar(navigationController?.navigationBar)
        theme.setupLabels(themableLabels)
        
        tableView.reloadData()
    }
}
