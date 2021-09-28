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

import SafariAdGuardSDK
import DnsAdGuardSDK

protocol ISettingsResetor {
    func resetAllSettings()
}

// TODO: - New SDK supports settings reset, this object needs changes
// Reset statistics and settings
struct SettingsResetor: ISettingsResetor {

    // MARK: - Private properties

    private weak var appDelegate: AppDelegate?
    private let vpnManager: VpnManagerProtocol
    private let resources: AESharedResourcesProtocol
    private let purchaseService: PurchaseServiceProtocol
    private let safariProtection: SafariProtectionProtocol

    // MARK: - Init

    init(appDelegate: AppDelegate,
         vpnManager: VpnManagerProtocol,
         resources: AESharedResourcesProtocol,
         purchaseService: PurchaseServiceProtocol,
         safariProtection: SafariProtectionProtocol) {

        self.appDelegate = appDelegate
        self.vpnManager = vpnManager
        self.resources = resources
        self.purchaseService = purchaseService
        self.safariProtection = safariProtection
    }

    // MARK: - IResetSettings methods

    func resetAllSettings() {
        presentAlert()

        DispatchQueue(label: "reset_queue").async {
            DDLogInfo("(ResetSettings) resetAllSettings")

            self.safariProtection.reset { _ in
                // todo: process error
            }
            self.vpnManager.removeVpnConfiguration { _ in }
            self.resources.reset()
            resetStatistics()

            let group = DispatchGroup()
            group.enter()

            self.purchaseService.reset {
                group.leave()
            }
            group.wait()
 
            appDelegate?.setAppInterfaceStyle()

            let dnsProvidersManager: DnsProvidersManagerProtocol = ServiceLocator.shared.getService()!
            try? dnsProvidersManager.reset()

            if #available(iOS 14.0, *) {
                let nativeDnsManager: NativeDnsSettingsManagerProtocol = ServiceLocator.shared.getService()!
                nativeDnsManager.reset()
            }

            // Notify that settings were reset
            NotificationCenter.default.post(name: .resetSettings, object: self)

            DispatchQueue.main.async {
                appDelegate?.setMainPageAsCurrentAndPopToRootControllersEverywhere()
                DDLogInfo("(ResetSettings) Reseting is over")
            }
        }
    }

    // MARK: - Private methods

    private func resetStatistics(){
        /* Reseting statistics Start*/

        // delete database file
        let url = self.resources.sharedResuorcesURL().appendingPathComponent("dns-statistics.db")
        do {
            try FileManager.default.removeItem(atPath: url.path)
            DDLogInfo("(ResetSettings) Statistics removed successfully")
        } catch {
            DDLogInfo("(ResetSettings) Statistics removing error: \(error.localizedDescription)")
        }
    }

    private func presentAlert() {
        let alert = UIAlertController(title: nil, message: String.localizedString("loading_message"), preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating();

        alert.view.addSubview(loadingIndicator)
        appDelegate?.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
