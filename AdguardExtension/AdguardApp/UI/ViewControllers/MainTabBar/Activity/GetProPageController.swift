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

class GetProPageController: UIViewController {

    @IBOutlet weak var activityImage: UIImageView!
    @IBOutlet weak var titleLabel: ThemableLabel!
    @IBOutlet weak var tryButton: UIButton!
    @IBOutlet var themableLabels: [ThemableLabel]!

    private let theme: ThemeServiceProtocol = ServiceLocator.shared.getService()!
    private let purchaseService: PurchaseServiceProtocol = ServiceLocator.shared.getService()!

    override func viewDidLoad() {
        super.viewDidLoad()

        activityImage.image = UIImage(named: "activity")

        let product = purchaseService.standardProduct

        titleLabel.text = getTitleString(product: product).uppercased()

        updateTheme()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tryButton.layer.cornerRadius = tryButton.frame.height / 2
    }

    private func getTitleString(product: Product?) -> String {

        let period = product?.trialPeriod?.unit ?? .week
        let numberOfUnits = product?.trialPeriod?.numberOfUnits ?? 1

        var formatString : String = ""

        switch period {
        case .day:
            formatString = String.localizedString("getPro_full_access_days")
        case .week:
            if numberOfUnits == 1 {
                formatString = String.localizedString("getPro_full_access_days")
                return String.localizedStringWithFormat(formatString, 7)
            }
            formatString = String.localizedString("getPro_full_access_weeks")
        case .month:
            formatString = String.localizedString("getPro_full_access_months")
        case .year:
            formatString = String.localizedString("getPro_full_access_years")
        }

        let resultString : String = String.localizedStringWithFormat(formatString, numberOfUnits)

        return resultString
    }
}

extension GetProPageController: ThemableProtocol {
    func updateTheme(){
        view.backgroundColor = theme.backgroundColor
        theme.setupLabels(themableLabels)
    }
}
