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

final class AdvancedYouTubeBlockingController: UIViewController {

    //MARK: - Outlests
    @IBOutlet weak var blockYouTubeView: UIView!
    @IBOutlet weak var mainTextView: UITextView!
    @IBOutlet weak var doneTextView: UITextView!
    @IBOutlet var themableLabels: [ThemableLabel]!
    @IBOutlet weak var contentView: UIView!

    //MARK: - Properties
    private let themeService: ThemeServiceProtocol = ServiceLocator.shared.getService()!
    private let configuration: ConfigurationServiceProtocol = ServiceLocator.shared.getService()!


    //MARK: - ViewController lifeycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackButton()
        updateTheme()
    }

    //MARK: - Private methods
    private func setupShadow() {
        blockYouTubeView.backgroundColor = configuration.darkTheme ? UIColor.AdGuardColor.black3 : .white
        blockYouTubeView.layer.cornerRadius = 8.0
        blockYouTubeView.layer.shadowColor = configuration.darkTheme ? UIColor.white.withAlphaComponent(0.1).cgColor : UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.15).cgColor
        blockYouTubeView.layer.shadowColor = configuration.darkTheme ? UIColor.black.withAlphaComponent(0.5).cgColor : UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.15).cgColor
        blockYouTubeView.layer.shadowOpacity = 1.0
        blockYouTubeView.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
        blockYouTubeView.layer.shadowRadius = 8
    }

    private func setupMainText() {
        guard let image = UIImage(named: "share") else { return }

        let youtubeAppInstalled = UIApplication.youtubeAppInstalled()

        let urlText = youtubeAppInstalled ? "x-web-search://" : "https://youtube.com"
        guard let url = URL(string: urlText)?.absoluteString else { return }

        let text = String.localizedString(youtubeAppInstalled ? "block_youtube_ads_instructions_safari" : "block_youtube_ads_instructions")
        let formattedText = String(format: text, url, "%@")
        let attachmentSetttings = NSMutableAttributedString.AttachmentSettings(image: image,
                                                     topEdge: 2.5,
                                                     leftEdge: 5,
                                                     size: .customSize(width: image.size.width, height: image.size.height))

        let isIpad = traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
        let attributedText = NSMutableAttributedString.fromHtml(formattedText, fontSize: isIpad ? 24.0 : 16.0, color: themeService.grayTextColor, attachmentSettings: attachmentSetttings, textAlignment: .left)
        mainTextView.attributedText = attributedText
    }

    private func setupDoneTextView() {
        let text = String.localizedString(UIApplication.youtubeAppInstalled() ? "block_youtube_ads_instructions_done_text_safari" : "block_youtube_ads_instructions_done_text")
        let isIpad = traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
        let attributedText = NSMutableAttributedString.fromHtml(text, fontSize: isIpad ? 24.0 : 16.0, color: themeService.grayTextColor)
        doneTextView.attributedText = attributedText
    }
}

extension AdvancedYouTubeBlockingController: ThemableProtocol {
    func updateTheme() {
        view.backgroundColor = themeService.backgroundColor
        contentView.backgroundColor = themeService.backgroundColor
        themeService.setupLabels(themableLabels)
        setupMainText()
        setupDoneTextView()
        setupShadow()
    }
}
