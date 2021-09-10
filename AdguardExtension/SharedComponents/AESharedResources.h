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
#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    
    APVpnManagerTunnelModeSplit = 0,
    APVpnManagerTunnelModeFull = 1,
    APVpnManagerTunnelModeFullWithoutVPNIcon = 2,
} APVpnManagerTunnelMode;

@class ASDFilterMetadata, ASDFilter, ABECFilterClientMetadata, ASDFilterRule, AEInvertedWhitelistDomainsObject, ABECFilterClientLocalization, DnsServerInfo;

/////////////////////////////////////////////////////////////////////
#pragma mark - AESharedResources Constants
/////////////////////////////////////////////////////////////////////

#define AE_PRODUCT_NAME                     @AG_PRODUCT
#define AE_HOSTAPP_ID                       @ADGUARD_BUNDLE_ID
//#define AE_EXTENSION_ID                     @ADGUARD_EXTENSION_BUNDLE_ID
#define AE_SHARED_RESOURCES_GROUP           @ADGUARD_SHARED_RESOURCES_GROUP
#define AE_FILTER_UPDATES_ID                @ADGUARD_FILTER_UPDATES_ID

#define AE_PRODUCTION_DB                    @"adguard.db"

extern NSString * _Nonnull AE_URLSCHEME;

/**
 User Defaults key that defines app performs first start or not.
 */
extern NSString * _Nonnull AEDefaultsFirstRunKey;
/**
 User Defaults key that defines schema version for upgrade procedure.
 */
extern NSString * _Nonnull AEDefaultsProductSchemaVersion;

/**
 User Defaults key that defines last used build version for upgrade procedure.
 */
extern NSString * _Nonnull AEDefaultsProductBuildVersion;

/**
 User Defaults key that defines last time, when the application checked updates of filters.
 */
extern NSString * _Nonnull AEDefaultsCheckFiltersLastDate;

/**
 User Defaults key that define maximum of the rules count,
 which may be converted to content blocking JSON.
 */
extern NSString * _Nonnull AEDefaultsJSONMaximumConvertedRules;

/**
 User Defaults key, which defines that filter updates will performed only in Wi-Fi network.
 */
extern NSString * _Nonnull AEDefaultsWifiOnlyUpdates;

/**
 User Defaults key, which defines that content blocker must use inverted whitelist - blocks ads ONLY on sites from this list.
 */
extern NSString * _Nonnull AEDefaultsInvertedWhitelist;

/**
 User Defaults key, which defines number of entries into an app from last build version.
 */
extern NSString * _Nonnull AEDefaultsAppEntryCount;

/**
 User Defaults key, which defines whether rate app dialog was shown
 */
extern NSString * _Nonnull AEDefaultsRateAppShown;

/**
 User Defaults key, which defines that pro feature is purchased through in app purchases.
 */
extern NSString* _Nonnull  AEDefaultsIsProPurchasedThroughInApp;

/**
 User Defaults key, which defines that pro feature is purchased through Setapp framefork
 */
extern NSString* _Nonnull  AEDefaultsIsProPurchasedThroughSetapp;

/**
 User Defaults key, which defines that pro feature is purchased.
 */
extern NSString* _Nonnull  AEDefaultsIsProPurchasedThroughLogin;

/**
 User defaults key, which contains premium account expiration date (NSDate) */
extern NSString* _Nonnull AEDefaultsPremiumExpirationDate;

/**
 User defaults key, which defines tha user has premium license */
extern NSString* _Nonnull AEDefaultsHasPremiumLicense;

/**
 User defaults key, which contains In app purchase subscription expiration date (NSDate) */
extern NSString* _Nonnull AEDefaultsRenewableSubscriptionExpirationDate;

/**
 User defaults key, which defines that non consumable item has been purchased */
extern NSString* _Nonnull AEDefaultsNonConsumableItemPurchased;

/**
 User defaults key, which defines dark theme is on */
extern NSString*  _Nonnull AEDefaultsDarkTheme;

/**
 User defaults key, which defines system appearence style */
extern NSString* _Nonnull AEDefaultsSystemAppearenceStyle;

/**
 User defaults key, which defines dark theme is on */
extern NSString*  _Nonnull AEDefaultsAuthStateString;

/**
 User defaults key, which defines that appId allready saved with right access rights.
 */
// todo: remove this in future
extern NSString*  _Nonnull AEDefaultsAppIdSavedWithAccessRights;

/**
 User defaults key, which defines user filter is enabled */
extern NSString*  _Nonnull AEDefaultsUserFilterEnabled;

/**
 User defaults key, which defines user filter is enabled */
extern NSString*  _Nonnull AEDefaultsSafariWhitelistEnabled;

/**
 User defaults key, which defines wifi exceptions is enabled */
extern NSString*  _Nonnull AEDefaultsFilterWifiEnabled;

/**
 User defaults key, which defines mobile data filtering is enabled */
extern NSString*  _Nonnull AEDefaultsFilterMobileEnabled;

/**
 User defaults key, which defines dns whitelist is enabled */
extern NSString*  _Nonnull AEDefaultsDnsWhitelistEnabled;

/**
 User defaults key, which defines dns  blacklist is enabled */
extern NSString*  _Nonnull AEDefaultsDnsBlacklistEnabled;

/**
 User defaults keys, which contains number of rules for each content blocker*/
extern NSString*  _Nonnull AEDefaultsGeneralContentBlockerRulesCount;
extern NSString*  _Nonnull AEDefaultsPrivacyContentBlockerRulesCount;
extern NSString*  _Nonnull AEDefaultsSocialContentBlockerRulesCount;
extern NSString*  _Nonnull AEDefaultsOtherContentBlockerRulesCount;
extern NSString*  _Nonnull AEDefaultsCustomContentBlockerRulesCount;
extern NSString*  _Nonnull AEDefaultsSecurityContentBlockerRulesCount;

/**
 User defaults keys, which contains number of over limited rules for each content blocker*/
extern NSString*  _Nonnull AEDefaultsGeneralContentBlockerRulesOverLimitCount;
extern NSString*  _Nonnull AEDefaultsPrivacyContentBlockerRulesOverLimitCount;
extern NSString*  _Nonnull AEDefaultsSocialContentBlockerRulesOverLimitCount;
extern NSString*  _Nonnull AEDefaultsOtherContentBlockerRulesOverLimitCount;
extern NSString*  _Nonnull AEDefaultsCustomContentBlockerRulesOverLimitCount;
extern NSString*  _Nonnull AEDefaultsSecurityContentBlockerRulesOverLimitCount;

/**
 User default key, which indicates whether safari protection is enabled*/
extern NSString* _Nonnull SafariProtectionState;

/**
 User defaults key, which defines, whether restart by reachability is enabled */
extern NSString* _Nonnull AEDefaultsRestartByReachability;

/**
 User defaults key, which defines log level (debug/normal) */
extern NSString* _Nonnull AEDefaultsDebugLogs;

/**
 User defaults key, which defines vpn tunnel mode */
extern NSString* _Nonnull AEDefaultsVPNTunnelMode;

/**
 User defaults key, which defines whether developer mode is enabled */
extern NSString* _Nonnull AEDefaultsDeveloperMode;

/**
 User defaults key, which defines whether show progress bar is enabled */
extern NSString* _Nonnull AEDefaultsShowStatusBar;

/**
 User defaults key, which defines number of requests
 made in period of logs writing
 */
extern NSString* _Nonnull AEDefaultsRequests;

/**
 User defaults key, which defines number of blocked requests
 made in period of logs writing
 */
extern NSString* _Nonnull AEDefaultsEncryptedRequests;

/**
 User defaults key, which defines last statistics save time
 */
extern NSString*  _Nonnull LastStatisticsSaveTime;

/**
 String to send notifications for StatusView
 */
extern NSString* _Nonnull AEDefaultsShowStatusViewInfo;

/**
 Notify to show status view
 */
extern NSString* _Nonnull ShowStatusViewNotification;

/**
 Hide status view
 */
extern NSString* _Nonnull HideStatusViewNotification;

/**
 Unique id for dns filters
 */
extern NSString* _Nonnull DnsFilterUniqueId;

/**
 User defaults key for saving statistics period type ( all time / week / day)
 */
extern NSString* _Nonnull StatisticsPeriodType;

/**
 User defaults key for saving activity statistics period type ( all time / week / day)
 */
extern NSString* _Nonnull ActivityStatisticsPeriodType;

/**
 User defaults key for current statistics save intervals
 */
extern NSString* _Nonnull StatisticsSaveTime;

/**
 User defaults key for activeProtocols in dns servers
 */
extern NSString* _Nonnull DnsActiveProtocols;

/**
 User defaults key for active dns server
 */
extern NSString* _Nonnull ActiveDnsServer;

/**
User defaults key for complex protection state
*/
extern NSString* _Nonnull AEComplexProtectionEnabled;
/**
 User defaults key, which defines whethet onboarding was shown
 */
extern NSString* _Nonnull OnboardingWasShown;

/**
 User defaults key, which defines tunnel error code when starting proxy
 */
extern NSString* _Nonnull TunnelErrorCode;

/**
 User defaults key, which defines background fetch state
 */
extern NSString* _Nonnull BackgroundFetchStateKey;

/**
 User defaults key for migrations.
 */
extern NSString* _Nonnull NeedToUpdateFiltersKey;

/**
 User defaults key for storing current DNS implementation.
 */
extern NSString* _Nonnull DnsImplementationKey;

/**
 User defaults key for custom fallback server.
 */
extern NSString* _Nonnull CustomFallbackServers;

/**
 User defaults key for custom bootstrap server.
 */
extern NSString* _Nonnull CustomBootstrapServers;

/**
 User defaults key for blocking mode.
 */
extern NSString* _Nonnull BlockingMode;

/**
 User defaults key for blocked response Ttl in secs.
 */
extern NSString* _Nonnull BlockedResponseTtlSecs;

/**
 User defaults key for custom blocking Ipv4.
 */
extern NSString* _Nonnull CustomBlockingIp;

/**
 User defaults key for custom blocking Ipv4.
 */
extern NSString* _Nonnull CustomBlockingIpv4;

/**
 User defaults key for custom blocking Ipv6
 */
extern NSString* _Nonnull CustomBlockingIpv6;

/**
 User defaults key for block Ipv6
 */
extern NSString* _Nonnull BlockIpv6;

/**
 User defaults key for last dns filters update time
 */
extern NSString* _Nonnull LastDnsFiltersUpdateTime;

/**
 User defaults key for advanced protection state
 */
extern NSString* _Nonnull AdvancedProtection;

/**
 User defaults key for advanced protection permissions granted state
 */
extern NSString* _Nonnull AdvancedProtectionPermissionsGranted;

/**
 User defaults key for safari web extension is on state
 */
extern NSString* _Nonnull SafariWebExtensionIsOn;

/**
 User defaults key for advanced protection whats new info screen shown
 */
extern NSString* _Nonnull AdvancedProtectionWhatsNewScreenShown;

/////////////////////////////////////////////////////////////////////
#pragma mark - AESharedResources
/////////////////////////////////////////////////////////////////////

/**
     Class, which provides exchanging data between app and extension.
 */
@protocol AESharedResourcesProtocol

/////////////////////////////////////////////////////////////////////
#pragma mark Properties and public methods
/////////////////////////////////////////////////////////////////////

/**
 Returns URL where is shared resources.
 */
- (nonnull NSURL *)sharedResuorcesURL;

/**
 Returns URL where must be current application logs.
 */
- (nonnull NSURL *)sharedAppLogsURL;

/**
 Returns URL where must be the applications logs.
 */
- (nonnull NSURL *)sharedLogsURL;

/**
 Returns shared user defaults object.
 */
- (nonnull NSUserDefaults *)sharedDefaults;

/**
 reset user defaults to initial state
 */
- (void) reset;

/**
 Performs flush of the shared user defaults.
 */
- (void)synchronizeSharedDefaults;

/**
 saves @data to file with @relativePath
 returns YES if succeded
 */
- (BOOL)saveData:(nonnull NSData *)data toFileRelativePath:(nonnull NSString *)relativePath;

/**
 read data from file
 */
- (nullable NSData *)loadDataFromFileRelativePath:(nonnull NSString *)relativePath;

- (nonnull NSString*) pathForRelativePath:(nonnull NSString*) relativePath;

@property BOOL safariProtectionEnabled;

@property BOOL systemProtectionEnabled;

@end

@interface AESharedResources: NSObject<AESharedResourcesProtocol>

@end
