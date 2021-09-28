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

struct SafariTagButtonModel {
    let tagName: String
    let isLang: Bool
    let isSelected: Bool
}

extension SafariTagButtonModel {
    init(tag: ExtendedFiltersMeta.Tag, isSelected: Bool) {
        self.tagName = "#" + tag.tagName
        self.isLang = tag.tagType == .lang
        self.isSelected = isSelected
    }
}

extension SafariTagButtonModel {
    init() {
        self.tagName = ""
        self.isLang = false
        self.isSelected = false
    }
}

final class SafariTagButton: UIButton {

    // MARK: - Public properties

    let model: SafariTagButtonModel

    // MARK: - Private properties

    private var tagCornerRadius: CGFloat { isIpadTrait ? 5.0 : 3.0 }
    private var buttonHeight: CGFloat { isIpadTrait ? 32.0 : 22.0 }
    private var langButtonWidth: CGFloat { isIpadTrait ? 40.0 : 30.0 }
    private var tagFont: UIFont { UIFont.systemFont(ofSize: isIpadTrait ? 18.0 : 12.0, weight: .regular) }
    private var buttonTextInset: CGFloat { isIpadTrait ? 12.0 : 6.0 }

    private let langFlags = [
        "en":"gb",
        "zh":"cn",
        "ja":"jp",
        "ko":"kr",
        "fa":"ir",
        "vi":"vn",
        "el":"gr",
        "da":"dk",
        "he":"il",
        "cs":"cz",
        "sv":"se",
        "ar":"sa",
        "et":"ee"
    ]

    // MARK: - Initialization

    required init?(coder: NSCoder) {
        self.model = SafariTagButtonModel()
        super.init(coder: coder)
        initializeTag()
    }

    override init(frame: CGRect) {
        self.model = SafariTagButtonModel()
        super.init(frame: frame)
        initializeTag()
    }

    init(model: SafariTagButtonModel) {
        self.model = model
        super.init(frame: .zero)
        model.isLang ? initializeLang() : initializeTag()
    }

    // MARK: - Public methods

    func updateTheme(_ themeService: ThemeServiceProtocol) {
        if !model.isLang {
            backgroundColor = themeService.tagColor
            setTitleColor(themeService.placeholderTextColor, for: .normal)
        }
    }

    // MARK: - Private methods

    private func initializeTag() {
        setTitle(model.tagName, for: .normal)
        setTitle(model.tagName, for: .selected)

        titleLabel?.font = tagFont
        layer.cornerRadius = tagCornerRadius
        layer.masksToBounds = true

        alpha = model.isSelected ? 1.0 : 0.3

        var desiredFrame = sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: buttonHeight))
        titleEdgeInsets = UIEdgeInsets(top: 2.0, left: buttonTextInset, bottom: 2.0, right: buttonTextInset)
        desiredFrame.width += 2 * buttonTextInset

        frame.size = desiredFrame
    }

    private func initializeLang() {
        var flag = model.tagName
        if flag.starts(with: "#") {
            flag = String(flag.dropFirst())
        }
        flag = langFlags[flag] ?? flag
        let flagImage = UIImage(named: flag)
        setImage(flagImage, for: .normal)
        setImage(flagImage, for: .selected)
        imageView?.contentMode = .scaleAspectFill

        layer.cornerRadius = tagCornerRadius
        layer.masksToBounds = true

        alpha = model.isSelected ? 1.0 : 0.3

        frame.size.height = buttonHeight
        frame.size.width = langButtonWidth
    }
}
