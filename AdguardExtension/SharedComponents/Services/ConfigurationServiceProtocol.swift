
import Foundation

@objc
protocol ConfigurationServiceProtocol : NSObjectProtocol {
    var darkTheme: Bool { get }
    var userThemeMode: AEThemeMode { get }
    var systemAppearenceIsDark: Bool { get }
    var proStatus : Bool { get }
    var appRated: Bool { get set }
    var advancedMode: Bool { get  set }
    var showStatusBar: Bool { get set }
    var allContentBlockersEnabled: Bool { get }
    var someContentBlockersEnabled: Bool { get }
}
