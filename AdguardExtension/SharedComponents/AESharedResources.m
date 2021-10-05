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
#import "AESharedResources.h"
#import "ACommons/ACLang.h"
#import "NSString+Utils.h"

NSString *AE_URLSCHEME = @ADGUARD_URL_SCHEME;

NSString *AEDefaultsFirstRunKey = @"AEDefaultsFirstRunKey";
NSString *AEDefaultsProductSchemaVersion = @"AEDefaultsProductSchemaVersion";
NSString *AEDefaultsProductBuildVersion = @"AEDefaultsProductBuildVersion";
NSString *AEDefaultsCheckFiltersLastDate = @"AEDefaultsCheckFiltersLastDate";
NSString *AEDefaultsJSONMaximumConvertedRules = @"AEDefaultsJSONMaximumConvertedRules";
NSString *AEDefaultsWifiOnlyUpdates = @"AEDefaultsWifiOnlyUpdates";
NSString *AEDefaultsInvertedWhitelist = @"AEDefaultsInvertedWhitelist";
NSString *AEDefaultsAppEntryCount = @"AEDefaultsAppEntryCount";
NSString *AEDefaultsRateAppShown = @"AEDefaultsRateAppShown";
NSString *AEDefaultsIsProPurchasedThroughInApp = @"AEDefaultsIsProPurchasedThroughInApp";
NSString *AEDefaultsIsProPurchasedThroughSetapp = @"AEDefaultsIsProPurchasedThroughSetapp";
NSString *AEDefaultsIsProPurchasedThroughLogin = @"AEDefaultsIsProPurchasedThroughLogin";
NSString *AEDefaultsPremiumExpirationDate = @"AEDefaultsPremiumExpirationDate";
NSString *AEDefaultsHasPremiumLicense = @"AEDefaultsHasPremiumLicense";
NSString *AEDefaultsRenewableSubscriptionExpirationDate = @"AEDefaultsRenewableSubscriptionExpirationDate";
NSString* AEDefaultsNonConsumableItemPurchased = @"AEDefaultsNonConsumableItemPurchased";
NSString* AEDefaultsDarkTheme = @"AEDefaultsDarkTheme";
NSString* AEDefaultsSystemAppearenceStyle = @"AEDefaultsSystemAppearenceStyle";
NSString* AEDefaultsAuthStateString = @"AEDefaultsAuthStateString";
NSString* AEDefaultsAppIdSavedWithAccessRights = @"AEDefaultsAppIdSavedWithAccessRights";
NSString* AEDefaultsUserFilterEnabled = @"AEDefaultsUserFilterEnabled";
NSString* AEDefaultsSafariWhitelistEnabled = @"AEDefaultsWhitelistEnabled";
NSString* AEDefaultsDnsWhitelistEnabled = @"AEDefaultsDnsWhitelistEnabled";
NSString* AEDefaultsDnsBlacklistEnabled = @"AEDefaultsDnsBlacklistEnabled";

NSString* AEDefaultsGeneralContentBlockerRulesCount = @"AEDefaultsGeneralContentBlockerRulesCount";
NSString* AEDefaultsPrivacyContentBlockerRulesCount = @"AEDefaultsPrivacyContentBlockerRulesCount";
NSString* AEDefaultsSocialContentBlockerRulesCount = @"AEDefaultsSocialContentBlockerRulesCount";
NSString* AEDefaultsOtherContentBlockerRulesCount = @"AEDefaultsOtherContentBlockerRulesCount";
NSString* AEDefaultsCustomContentBlockerRulesCount = @"AEDefaultsCustomContentBlockerRulesCount";
NSString* AEDefaultsSecurityContentBlockerRulesCount = @"AEDefaultsSecurityContentBlockerRulesCount";

NSString* AEDefaultsGeneralContentBlockerRulesOverLimitCount = @"AEDefaultsGeneralContentBlockerRulesOverLimitCount";
NSString* AEDefaultsPrivacyContentBlockerRulesOverLimitCount = @"AEDefaultsPrivacyContentBlockerRulesOverLimitCount";
NSString* AEDefaultsSocialContentBlockerRulesOverLimitCount = @"AEDefaultsSocialContentBlockerRulesOverLimitCount";
NSString* AEDefaultsOtherContentBlockerRulesOverLimitCount = @"AEDefaultsOtherContentBlockerRulesOverLimitCount";
NSString* AEDefaultsCustomContentBlockerRulesOverLimitCount = @"AEDefaultsCustomContentBlockerRulesOverLimitCount";
NSString* AEDefaultsSecurityContentBlockerRulesOverLimitCount = @"AEDefaultsSecurityContentBlockerRulesOverLimitCount";

NSString* AEDefaultsRestartByReachability = @"AEDefaultsRestartByReachability";
NSString* AEDefaultsDebugLogs = @"AEDefaultsDebugLogs";
NSString* AEDefaultsVPNTunnelMode = @"AEDefaultsVPNTunnelMode";
NSString* AEDefaultsDeveloperMode = @"AEDefaultsDeveloperMode";
NSString* AEDefaultsShowStatusBar = @"AEDefaultsShowStatusBar";

NSString* AEDefaultsRequests = @"AEDefaultsRequests";
NSString* AEDefaultsEncryptedRequests = @"AEDefaultsEncryptedRequests";
NSString* LastStatisticsSaveTime = @"LastStatisticsSaveTime";

NSString* AEDefaultsShowStatusViewInfo = @"AEDefaultsShowStatusViewInfo";
NSString *ShowStatusViewNotification = @"ShowStatusViewNotification";
NSString *HideStatusViewNotification = @"HideStatusViewNotification";

NSString* SafariProtectionState = @"SafariProtectionState";

NSString* DnsFilterUniqueId = @"DnsFilterUniqueId";

NSString *SafariProtectionLastState = @"SafariProtectionLastState";
NSString *SystemProtectionLastState = @"SystemProtectionLastState";

NSString *StatisticsPeriodType = @"StatisticsPeriodType";
NSString *ActivityStatisticsPeriodType = @"ActivityStatisticsPeriodType";
NSString *StatisticsSaveTime = @"StatisticsSaveTime";

NSString *DnsActiveProtocols = @"DnsActiveProtocols";

NSString* ActiveDnsServer = @"ActiveDnsServer";

NSString* AESystemProtectionEnabled = @"AESystemProtectionEnabled";

NSString* AEComplexProtectionEnabled = @"AEComplexProtectionEnabled";

NSString *OnboardingWasShown = @"OnboardingWasShown";

NSString *TunnelErrorCode = @"TunnelErrorCode";

NSString *BackgroundFetchStateKey = @"BackgroundFetchStateKey";

NSString *NeedToUpdateFiltersKey = @"NeedToUpdateFiltersKey";

NSString *DnsImplementationKey = @"DnsImplementationKey";

NSString *CustomFallbackServers = @"CustomFallbackServers";

NSString *CustomBootstrapServers = @"CustomBootstrapServers";

NSString *BlockingMode = @"BlockingMode";

NSString *BlockedResponseTtlSecs = @"BlockedResponseTtlSecs";

NSString *CustomBlockingIp = @"CustomBlockingIp";

NSString *CustomBlockingIpv4 = @"CustomBlockingIpv4";

NSString *CustomBlockingIpv6 = @"CustomBlockingIpv6";

NSString *BlockIpv6 = @"BlockIpv6";

NSString* LastDnsFiltersUpdateTime = @"LastDnsFiltersUpdateTime";

#define AES_HOST_APP_USERDEFAULTS               @"host-app-userdefaults.data"

/////////////////////////////////////////////////////////////////////
#pragma mark - AESharedResources
/////////////////////////////////////////////////////////////////////

@implementation AESharedResources {
    NSURL *_containerFolderUrl;
    NSUserDefaults *_sharedUserDefaults;
}

/////////////////////////////////////////////////////////////////////
#pragma mark Initialize
/////////////////////////////////////////////////////////////////////

+ (void)initialize{

    if (self == [AESharedResources class]) {
    }
}

#pragma mark - init

- (instancetype)init {
    self = [super init];
    NSString* groupId = AE_SHARED_RESOURCES_GROUP;
    _containerFolderUrl = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupId];
    _sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:AE_SHARED_RESOURCES_GROUP];
    return self;
}

/////////////////////////////////////////////////////////////////////
#pragma mark Properties and public methods
/////////////////////////////////////////////////////////////////////


- (NSURL *)sharedResuorcesURL{

    return _containerFolderUrl;
}

- (NSURL *)sharedAppLogsURL{

    NSString *ident = [[NSBundle bundleForClass:[self class]] bundleIdentifier];

    NSURL *logsUrl = [self sharedLogsURL];
    if (ident) {
        logsUrl = [logsUrl URLByAppendingPathComponent:ident];
    }

    return logsUrl;
}

- (NSURL *)sharedLogsURL{

    return [_containerFolderUrl URLByAppendingPathComponent:@"Logs"];
}

- (void)reset {

    for (NSString* key in _sharedUserDefaults.dictionaryRepresentation.allKeys) {
        [_sharedUserDefaults removeObjectForKey:key];
    }
    [_sharedUserDefaults synchronize];

    // remove all files in shared directory

    NSFileManager *fm = [NSFileManager defaultManager];

    NSError *error = nil;
    for (NSString *file in [fm contentsOfDirectoryAtPath:_containerFolderUrl.path error:&error]) {

        // FIXME: Maybe we should get this strings from some constants
        if (([file isEqual: @"db_files"]) || ([file isEqual: @"filters"]) || ([file isEqual: @"cb_jsons" ])) { continue; }
        BOOL success = [fm removeItemAtPath:[NSString stringWithFormat:@"%@/%@", _containerFolderUrl.path, file] error:&error];
        if (!success || error) {
        }
    }
}

- (NSUserDefaults *)sharedDefaults{

    return _sharedUserDefaults;
}

- (void)synchronizeSharedDefaults{

    [_sharedUserDefaults synchronize];
}

- (BOOL)safariProtectionEnabled{
    NSNumber *safariEnabled = [self.sharedDefaults objectForKey:SafariProtectionState];
    return safariEnabled == nil ? YES : safariEnabled.boolValue;
}

- (void)setSafariProtectionEnabled:(BOOL)safariProtectionEnabled{
    [self.sharedDefaults setBool:safariProtectionEnabled forKey:SafariProtectionState];
}

- (BOOL)systemProtectionEnabled {
    return [self.sharedDefaults boolForKey:AESystemProtectionEnabled]; // default false
}

- (void)setSystemProtectionEnabled:(BOOL)enabled {
    [self.sharedDefaults setBool:enabled forKey:AESystemProtectionEnabled];
}

/////////////////////////////////////////////////////////////////////
#pragma mark Storage methods (private)
/////////////////////////////////////////////////////////////////////


- (NSData *)loadDataFromFileRelativePath:(NSString *)relativePath{

    if (!relativePath) {
         [[NSException argumentException:@"relativePath"] raise];
    }

    @autoreleasepool {
        if (_containerFolderUrl) {

            NSURL *dataUrl = [_containerFolderUrl URLByAppendingPathComponent:relativePath];
            if (dataUrl) {
                ACLFileLocker *locker = [[ACLFileLocker alloc] initWithPath:[dataUrl path]];
                if ([locker waitLock]) {

                    NSData *data = [NSData dataWithContentsOfURL:dataUrl];

                    [locker unlock];

                    return data;
                }
            }
        }

        return nil;
    }
}

- (BOOL)saveData:(NSData *)data toFileRelativePath:(NSString *)relativePath{

    if (!(data && relativePath)) {
        [[NSException argumentException:@"data/relativePath"] raise];
    }

    @autoreleasepool {
        if (_containerFolderUrl) {

            NSURL *dataUrl = [_containerFolderUrl URLByAppendingPathComponent:relativePath];
            if (dataUrl) {
                ACLFileLocker *locker = [[ACLFileLocker alloc] initWithPath:[dataUrl path]];
                if ([locker lock]) {

                    BOOL result = [data writeToURL:dataUrl atomically:YES];

                    [locker unlock];

                    return result;
                }
            }
        }

        return NO;;
    }
}

- (NSString*) pathForRelativePath:(NSString*) relativePath {

    NSURL *dataUrl = [_containerFolderUrl URLByAppendingPathComponent:relativePath];

    return dataUrl.path;
}

@end

