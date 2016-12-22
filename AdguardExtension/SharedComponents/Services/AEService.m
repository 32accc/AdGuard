/**
    This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
    Copyright © 2015 Performix LLC. All rights reserved.

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
#import <SafariServices/SafariServices.h>
#import "AEService.h"
#import "ACommons/ACLang.h"
#import "AppDelegate.h"
#import "AESAntibanner.h"
#import "ASDFilterObjects.h"
#import "AESFilterConverter.h"
#import "AESharedResources.h"
#import "AEFilterRuleSyntaxConstants.h"
#import "AEWhitelistDomainObject.h"

NSString *AEServiceErrorDomain = @"AEServiceErrorDomain";

/////////////////////////////////////////////////////////////////////
#pragma mark - AEServices
/////////////////////////////////////////////////////////////////////

#define AES_RELOADJSON_TASK_NAME        @"AEService-Reload_JSON"

typedef enum {
    
    RFNotReadyType = 0,
    RFAntibannerInstalledType = 1,
    RFAntibannerReadyType = 2,
    
    RFAllReadyType = RFAntibannerInstalledType | RFAntibannerReadyType
    
} ReadyFlagType;

@interface AEService (){
    
    dispatch_queue_t workQueue;
    AESAntibanner *antibanner;
    AESharedResources *_sharedResources;

    NSMutableArray *_onReadyBlocks;
    ReadyFlagType _readyFlags;
    NSLock *_readyLock;
    
    NSMutableArray *_onReloadContentBlockingJsonBlocks;
    BOOL _reloadContentBlockingJsonComplate;
    NSLock *_reloadContentBlockingJsonLock;
    UIBackgroundTaskIdentifier _reloadContentBlockingJsonLongTaskId;
    
    BOOL started;
}

@end

@implementation AEService

static AEService *singletonService;

/////////////////////////////////////////////////////////////////////
#pragma mark Init and Class methods
/////////////////////////////////////////////////////////////////////

- (id)init{
    
    self = [super init];
    if (self) {
        
        workQueue = dispatch_queue_create("AAService", DISPATCH_QUEUE_SERIAL);
        
        //------------ Checking First Running -----------------------------
        [self checkFirstRunning];
        
        // Subscribing to Antibanner notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(antibanNotify:) name:ASAntibannerReadyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(antibanNotify:) name:ASAntibannerInstalledNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(antibanNotify:) name:ASAntibannerNotInstalledNotification object:nil];
        
        
        antibanner = [AESAntibanner new];
        _readyLock = [NSLock new];
        _reloadContentBlockingJsonLock = [NSLock new];
        _reloadContentBlockingJsonComplate = YES;
        _reloadContentBlockingJsonLongTaskId = UIBackgroundTaskInvalid;

    }
    
    return self;
}

- (void)dealloc{
    
    [self stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


+ (AEService *)singleton{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        singletonService = [AEService new];
    });
    
    return singletonService;
    
}

/////////////////////////////////////////////////////////////////////////
#pragma mark Properties and public methods
/////////////////////////////////////////////////////////////////////////


- (void)start{
    
    @synchronized(self){
        
        if (started) return;
        

        // Init shared resources
        _sharedResources = [AESharedResources new];

        // Enabling antibanner service
        if (_firstRunInProgress) {
            [antibanner beginTransaction];
        }
        antibanner.enabled = YES;
        
        started = YES;
    }
}

- (void)stop{
    
    @synchronized(self){
        
        if (!started) return;
        
        _sharedResources = nil;
        
        // Disabling antibanner service
        antibanner.enabled = NO;
        
        _readyFlags = RFNotReadyType;
        
        started = NO;
    }
}

- (AESAntibanner *)antibanner{

    return antibanner;
}

- (NSError *)updateRule:(ASDFilterRule *)rule oldRuleText:(NSString *)oldRuleText{

    @autoreleasepool {
        if ([rule.ruleText isEqualToString:oldRuleText]) {
            
            return [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_ARGUMENT userInfo:nil];
        }
        
        if ([NSString isNullOrEmpty:rule.ruleText]) {
            
            return [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_ARGUMENT userInfo:nil];
        }
        
        //Check that rule may be converted
        if (![rule.ruleText hasPrefix:COMMENT]) {
            
            BOOL optimize = [[AESharedResources sharedDefaults] boolForKey:AEDefaultsJSONConverterOptimize];
            
            NSError *error = nil;
            [self convertOneRule:rule optimize:optimize error:&error];
            
            if (error) {
                return error;
            }
        }
        //
        
        BOOL result = [antibanner updateRule:rule];
        
        if (result) {
            return nil;
        }
        
        return [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_DB userInfo:nil];
    }
}

- (NSError *)addRule:(ASDFilterRule *)rule temporarily:(BOOL)temporarily {

    @autoreleasepool {

        if ([NSString isNullOrEmpty:rule.ruleText]) {
            
            return [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_ARGUMENT userInfo:nil];
        }
        
        //Check that rule may be converted
        if (![rule.ruleText hasPrefix:COMMENT]) {
            
            BOOL optimize = [[AESharedResources sharedDefaults] boolForKey:AEDefaultsJSONConverterOptimize];
            
            NSError *error = nil;
            [self convertOneRule:rule optimize:optimize error:&error];
            
            if (error) {
                return error;
            }
        }
        //

        BOOL result = temporarily;
        if (!result) {
            result = [antibanner addRule:rule];
        }

        if (result) {
            return nil;
        }
        
        return [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_DB userInfo:nil];
    }
}

- (BOOL)removeRules:(NSArray *)rules {

    @autoreleasepool {

        BOOL result = NO;

        NSNumber *filterId = [[rules firstObject] filterId];
        result = [antibanner removeRules:[rules valueForKey:@"ruleId"]
                                filterId:filterId];
        return result;
    }
}

- (void)addWhitelistRule:(ASDFilterRule *)rule completionBlock:(void (^)(NSError *error))completionBlock {

    if (!started) {
        return;
    }
    
    [_reloadContentBlockingJsonLock lock];
    _reloadContentBlockingJsonComplate = NO;
    [_reloadContentBlockingJsonLock unlock];

    dispatch_async(workQueue, ^{

        NSError *error = nil;
        BOOL jsonNotModified = YES;
        NSDictionary *convertResult;

        do {

            if (!(rule && [[AEWhitelistDomainObject alloc] initWithRule:rule])) {
                
                error = [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_ARGUMENT userInfo:nil];
                break;
            }

            BOOL result = NO;

            result = [antibanner addRule:rule];

            if (!result) {

                error = [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_DB userInfo:nil];
                break;
            }

            NSInteger maxRules = [[[AESharedResources sharedDefaults]
                objectForKey:AEDefaultsJSONMaximumConvertedRules] integerValue];
            NSInteger convertedRules = [[[AESharedResources sharedDefaults]
                objectForKey:AEDefaultsJSONConvertedRules] integerValue];
            NSInteger totalConvertedRulesCount = [[[AESharedResources sharedDefaults]
                objectForKey:AEDefaultsJSONRulesForConvertion] integerValue];

            // add rule to json if we have space for that
            if ((maxRules - convertedRules)) {

                NSError *error = nil;
                convertResult = [self convertOneRule:rule optimize:NO error:&error];

                if (error) {
                    break;
                }

                NSString *jsonRule = convertResult[AESFConvertedRulesKey];
                if (![NSString isNullOrEmpty:jsonRule]) {

                    @autoreleasepool {

                        NSMutableData *jsonData = [NSMutableData dataWithData:_sharedResources.blockingContentRules];
                        //
                        [jsonData replaceBytesInRange:NSMakeRange(jsonData.length - 2, 2) withBytes:",\n"];
                        // add whitelist rule
                        NSData *jsonRuleData = [jsonRule dataUsingEncoding:NSUTF8StringEncoding];
                        [jsonData appendBytes:([jsonRuleData bytes] + 2) length:(jsonRuleData.length - 2)];

                        _sharedResources.blockingContentRules = jsonData;

                        totalConvertedRulesCount++;
                        convertedRules++;
                        [AESharedResources sharedDefaultsSetTempKey:AEDefaultsJSONRulesForConvertion value:@(totalConvertedRulesCount)];
                        [AESharedResources sharedDefaultsSetTempKey:AEDefaultsJSONConvertedRules value:@(convertedRules)];
                        
                        jsonNotModified = NO;
                    }
                }
            }

        } while (0);

        //reloading

        if (error || jsonNotModified) {
            [self finishReloadingContentBlockingJsonWithCompletionBlock:completionBlock error:error];
            return;
        }

        // after reloading notify Safari
        [self invalidateJsonInSafariWithCompletionBlock:completionBlock backgroundUpdate:NO];
    });
}

- (void)removeWhitelistRule:(ASDFilterRule *)rule completionBlock:(void (^)(NSError *error))completionBlock {
    
    if (!started) {
        return;
    }
    
    
    [_reloadContentBlockingJsonLock lock];
    _reloadContentBlockingJsonComplate = NO;
    [_reloadContentBlockingJsonLock unlock];
    
    dispatch_async(workQueue, ^{
        
        NSError *error = nil;
        BOOL jsonNotModified = YES;
        NSDictionary *convertResult;
        
        do {
            
            if (!(rule && [[AEWhitelistDomainObject alloc] initWithRule:rule])) {
                
                error = [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_ARGUMENT userInfo:nil];
                break;
            }
            
            BOOL result = NO;
            
            result = [self removeRules:@[rule]];
            
            if (!result) {
                
                error = [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_DB userInfo:nil];
                break;
            }
            
            NSInteger convertedRules = [[[AESharedResources sharedDefaults]
                                         objectForKey:AEDefaultsJSONConvertedRules] integerValue];
            NSInteger totalConvertedRulesCount = [[[AESharedResources sharedDefaults]
                                                   objectForKey:AEDefaultsJSONRulesForConvertion] integerValue];
            BOOL overlimit = [[AESharedResources sharedDefaults] boolForKey:AEDefaultsJSONRulesOverlimitReached];
            
            
                NSError *error = nil;
                convertResult = [self convertOneRule:rule optimize:NO error:&error];
                
                if (error) {
                    break;
                }
                
                NSString *jsonRule = convertResult[AESFConvertedRulesKey];
                if (![NSString isNullOrEmpty:jsonRule]) {
                    
                    @autoreleasepool {
                        
                        NSData *jsonRuleData = [jsonRule dataUsingEncoding:NSUTF8StringEncoding];
                        jsonRuleData = [NSData dataWithBytes:(jsonRuleData.bytes + 2) length:(jsonRuleData.length - 4)];
                        
                        NSMutableData *jsonData = [NSMutableData dataWithData:_sharedResources.blockingContentRules];
                        //find rule into json
                        NSRange loc = [jsonData rangeOfData:jsonRuleData options:NSDataSearchBackwards range:NSMakeRange(0, jsonData.length)];

                        if (loc.location != NSNotFound) {
                            
                            // delete 2 chars before
                            if (loc.location > 8) {
                                loc.location -= 2;
                                loc.length += 2;
                            }
                            
                            [jsonData replaceBytesInRange:loc withBytes:NULL length:0];
                            
                            _sharedResources.blockingContentRules = jsonData;
                            
                            totalConvertedRulesCount--;
                            convertedRules--;
                            overlimit = NO;
                            [AESharedResources sharedDefaultsSetTempKey:AEDefaultsJSONRulesForConvertion value:@(totalConvertedRulesCount)];
                            [AESharedResources sharedDefaultsSetTempKey:AEDefaultsJSONConvertedRules value:@(convertedRules)];
                            [AESharedResources sharedDefaultsSetTempKey:AEDefaultsJSONRulesOverlimitReached value:@(overlimit)];
                            
                            jsonNotModified = NO;
                        }
                    }
                }
            
        } while (0);
        
        //reloading
        
        if (error || jsonNotModified) {
            [self finishReloadingContentBlockingJsonWithCompletionBlock:completionBlock error:error];
            return;
        }
        
        // after reloading notify Safari
        [self invalidateJsonInSafariWithCompletionBlock:completionBlock backgroundUpdate:NO];
    });
}

- (void)reloadContentBlockingJsonASyncWithBackgroundUpdate:(BOOL)backgroundUpdate completionBlock:(void (^)(NSError *error))completionBlock{

    [_reloadContentBlockingJsonLock lock];
    _reloadContentBlockingJsonComplate = NO;
    [_reloadContentBlockingJsonLock unlock];

    dispatch_async(workQueue, ^{

#ifndef APP_EXTENSION
        //Long-running task init
        
        if (!backgroundUpdate) {
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                _reloadContentBlockingJsonLongTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithName:AES_RELOADJSON_TASK_NAME expirationHandler:^{
                    
                    //TODO: ceanup
                    
                    if (_reloadContentBlockingJsonLongTaskId != UIBackgroundTaskInvalid) {
                        [[UIApplication sharedApplication] endBackgroundTask:_reloadContentBlockingJsonLongTaskId];
                        _reloadContentBlockingJsonLongTaskId = UIBackgroundTaskInvalid;
                    }
                }];
            });
        }
#endif
        
        //reloading
        NSError *result = [self reloadContentBlockingJson];
        
        if (result) {
            [self finishReloadingContentBlockingJsonWithCompletionBlock:completionBlock error:result];
            return;
        }
        
        // after reloading notify Safari
        [self invalidateJsonInSafariWithCompletionBlock:completionBlock backgroundUpdate:backgroundUpdate];
    });
}

- (void)onReloadContentBlockingJsonComplete:(void (^)(void))block{
    
    [_reloadContentBlockingJsonLock lock];
    
    if (_reloadContentBlockingJsonComplate) {
        
        dispatch_async(workQueue, block);
    }
    else {
        
        if (!_onReloadContentBlockingJsonBlocks) {
            _onReloadContentBlockingJsonBlocks = [NSMutableArray new];
        }
        
        [_onReloadContentBlockingJsonBlocks addObject:[block copy]];
    }
    [_reloadContentBlockingJsonLock unlock];

}

- (void)onReady:(void (^)(void))block{
    
    DDLogDebugTrace();
    [_readyLock lock];

    if (_readyFlags == RFAllReadyType) {

        DDLogDebug(@"dispatch onReady block");
        dispatch_async(workQueue, block);
    }
    else {
        
        if (!_onReadyBlocks) {
            _onReadyBlocks = [NSMutableArray new];
        }
        
        DDLogDebug(@"delay onReady block");
        [_onReadyBlocks addObject:[block copy]];
    }
    [_readyLock unlock];
}

/////////////////////////////////////////////////////////////////////////
#pragma mark Notifications observers
/////////////////////////////////////////////////////////////////////////

- (void)antibanNotify:(NSNotification *)notification{
    
    // Success antibanner installed (first run)
    if ([notification.name isEqualToString:ASAntibannerInstalledNotification]){
        
        DDLogDebug(@"(AEService) ASAntibannerInstalledNotification received");

        [self reloadContentBlockingJsonASyncWithBackgroundUpdate:NO completionBlock:^(NSError *error) {
            
            // If error then disable all installed filters
            if (error) {
                
                for (ASDFilterMetadata *item in [antibanner filters]) {
                    if ([item.filterId integerValue] != ASDF_USER_FILTER_ID && [item.enabled boolValue]) {
                        [antibanner setFilter:item.filterId enabled:NO fromUI:NO];
                    }
                }
                
                [self reloadContentBlockingJsonASyncWithBackgroundUpdate:NO completionBlock:^(NSError *error) {
                    
                    // we think that no errors in this place. :)
                    if (error){
                        
                        [antibanner rollbackTransaction];
                    }
                    else{
                        
                        [self checkForServiceReady:RFAntibannerInstalledType];
                    }
                }];
                
                return;
            }
            
            // If no errors
            [self checkForServiceReady:RFAntibannerInstalledType];
        }];
    }
    // Antibanner ready
    else if ([notification.name isEqualToString:ASAntibannerReadyNotification]){
        
        DDLogDebug(@"(AEService) ASAntibannerReadyNotification received");
        // if this is not first running of the application we simulate antibanner "installed" notification
        if (!self.firstRunInProgress) {
            [self checkForServiceReady:RFAntibannerInstalledType];
        }
         
        [self checkForServiceReady:RFAntibannerReadyType];
    }
}

/////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods
/////////////////////////////////////////////////////////////////////////

- (NSError *)reloadContentBlockingJson{
    
    @synchronized(self) {
        @autoreleasepool {
            
            if (started) {
                DDLogInfo(@"(AEService) reloadContentBlockingJson started.");
                
                // Empty JSON
                NSData *json = [NSData data];
                
                NSNumber *convertedRulesCount = @(0);
                NSNumber *totalConvertedRulesCount = @(0);
                
                BOOL overlimit = NO;
                
                @autoreleasepool {
                    
                    NSString *jsonString;
                    
                    @autoreleasepool {
                        NSDictionary *result;
                        NSUInteger limit = [[[AESharedResources sharedDefaults] objectForKey:AEDefaultsJSONMaximumConvertedRules] unsignedIntegerValue];
                        BOOL optimize = [[AESharedResources sharedDefaults] boolForKey:AEDefaultsJSONConverterOptimize];
                        
                        @autoreleasepool {
                            
                            NSArray *rules = [self.antibanner activeRules];
                            if (rules.count) {
                                
                                // run converter
                                
                                @autoreleasepool {
                                    NSError *error = nil;
                                    AESFilterConverter *converterToJSON = [self createConverterToJsonWithError:&error];
                                    if (!converterToJSON) {
                                        return error;
                                    }
                                    
                                    result = [converterToJSON jsonFromRules:rules upTo:limit optimize:optimize];
                                }
                                
                                NSError *error = result[AESFConvertedErrorKey];
                                if (error) {
                                    return error;
                                }
                            }
                            
                            rules = nil;
                        }
                        
                        if (result) {
                            
                            // check overlimit
                            overlimit = [result[AESFCOverLimitKey] boolValue];
                            if (overlimit) {
                                
                                //now this is not fatal error.
                                DDLogWarn(@"(AEService) Can't convert all rules. Limit of the rules count exceeded. Rules count limit: %lu", limit);
                                
                                //                        NSString *errorDescription = NSLocalizedString(@"Exceeded the maximum number of filter rules.", @"(AEService) Service errors descriptions");
                                //                        return [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_JSON_CONVERTER_OVERLIMIT userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                                
                            }
                            
                            convertedRulesCount = result[AESFConvertedCountKey];
                            totalConvertedRulesCount = result[AESFTotalConvertedCountKey];
                            
                            // obtain rules
                            jsonString = result[AESFConvertedRulesKey];
                            
                            result = nil;
                            
                        }
                        
                    }
                    if (jsonString && !([jsonString isEqualToString:@"undefined"] || [jsonString isEqualToString:@"[]"])) {
                        json = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                    }
                    
                    jsonString = nil;
                }
        
                // Temporarily save current converted rules in user defaults
                [AESharedResources sharedDefaultsSetTempKey:AEDefaultsJSONRulesForConvertion value:totalConvertedRulesCount];
                [AESharedResources sharedDefaultsSetTempKey:AEDefaultsJSONRulesOverlimitReached value:@(overlimit)];
                [AESharedResources sharedDefaultsSetTempKey:AEDefaultsJSONConvertedRules value:convertedRulesCount];
                DDLogDebug(@"(AEService) Temporarily saved current converted rules in user defaults. Rules count: %@", convertedRulesCount);
                
                _sharedResources.blockingContentRules = json;
                
                DDLogInfo(@"(AEService) reloadContentBlockingJson successfuly finished.");
                
                return nil;
            }
            
            DDLogError(@"(AEService) Attempt converting rules to JSON when service not started.");
            DDLogErrorTrace();
            NSString *errorDescription = NSLocalizedString(@"Attempted to convert rules to JSON while service is not started.", @"(AEService) Service errors descriptions");
            return [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_SERVICE_NOT_STARTED userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
        }
    }
}

- (void)invalidateJsonInSafariWithCompletionBlock:(void (^)(NSError *error))completionBlock backgroundUpdate:(BOOL)backgroundUpdate {
    
    DDLogInfo(@"(AEService) Starting notify Safari - reloadContentBlockerWithIdentifier.");
    
    if (backgroundUpdate) {
        
        [SFContentBlockerManager
         reloadContentBlockerWithIdentifier:AE_EXTENSION_ID
         completionHandler:nil];
        
        [self savePermanentlyCountersOfConvertion];
        
        [self finishReloadingContentBlockingJsonWithCompletionBlock:completionBlock error:nil];
    }
    else{
        
    [SFContentBlockerManager
     reloadContentBlockerWithIdentifier:AE_EXTENSION_ID
     completionHandler: ^(NSError * _Nullable error) {
         
         DDLogInfo(@"(AEService) Finishing notify Safari - reloadContentBlockerWithIdentifier.");
         if (error) {
             
             DDLogError(@"(AEService) Error occured: %@", [error localizedDescription]);
             
             NSString *errorDescription = NSLocalizedString(@"Filters cannot be loaded into Safari. Therefore, your recent changes were not applied.", @"(AEService) Service errors descriptions");
             error =  [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_SAFARI_EXCEPTION userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
         }
         else{
             
             //no errors

             [self savePermanentlyCountersOfConvertion];
         }
         
         [AESharedResources sharedDefaultsRemoveTempKey:AEDefaultsJSONConvertedRules];
         
         DDLogInfo(@"(AEService) Notify Safari fihished.");
         
         [self finishReloadingContentBlockingJsonWithCompletionBlock:completionBlock error:error];
     }];
    }
}

- (void)savePermanentlyCountersOfConvertion{

    //Permanently save current converted rules in user defaults
    NSNumber *value = [[AESharedResources sharedDefaults] valueForKey:AEDefaultsJSONConvertedRules];
    if (value) {
        DDLogInfo(@"(AEService) Permanently saved current converted rules in user defaults.");
        [[AESharedResources sharedDefaults] setObject:value forKey:AEDefaultsJSONConvertedRules];
        DDLogInfo(@"Rules: %@", value);
        value = [[AESharedResources sharedDefaults] valueForKey:AEDefaultsJSONRulesForConvertion];
        [[AESharedResources sharedDefaults] setObject:value forKey:AEDefaultsJSONRulesForConvertion];
        DDLogInfo(@"From rules: %@", value);
        
        value = [[AESharedResources sharedDefaults] valueForKey:AEDefaultsJSONRulesOverlimitReached];
        [[AESharedResources sharedDefaults] setBool:[value boolValue] forKey:AEDefaultsJSONRulesOverlimitReached ];
        
    }

}

- (void)checkForServiceReady:(ReadyFlagType)readyFlag{

    [_readyLock lock];
    
    _readyFlags |= readyFlag;
    if (_readyFlags == RFAllReadyType) {

        if (_firstRunInProgress) {
            // Set first run to NO
            [[AESharedResources sharedDefaults]
             setBool:NO
             forKey:AEDefaultsFirstRunKey];
            [antibanner endTransaction];
        }
        
        [self pushReadyBlocksToWorkingQueue];
    }
    [_readyLock unlock];
}

- (void)pushReadyBlocksToWorkingQueue{

    DDLogDebugTrace();
    
    for (void (^ block)() in _onReadyBlocks) {
       
        dispatch_async(workQueue, block);
    }
    
    [_onReadyBlocks removeAllObjects];
    _onReadyBlocks = nil;
}

- (void)finishReloadingContentBlockingJsonWithCompletionBlock:(void (^)(NSError *error))completionBlock error:(NSError *)error{
    
    // perform delayed operations
    dispatch_async(workQueue, ^{
        
        if (completionBlock) {
            dispatch_async(workQueue, ^{
                completionBlock(error);
                [self finishLongRunningTask];
            });
        }
        else{
            
            [self finishLongRunningTask];
        }
        
        [_reloadContentBlockingJsonLock lock];
        
        _reloadContentBlockingJsonComplate = YES;
        for (void (^ block)() in _onReloadContentBlockingJsonBlocks) {
            
            dispatch_async(workQueue, block);
        }
        
        [_onReloadContentBlockingJsonBlocks removeAllObjects];
        _onReloadContentBlockingJsonBlocks = nil;
        
        [_reloadContentBlockingJsonLock unlock];
        
    });
}

// If application is launched first time.
- (void)checkFirstRunning {
    @autoreleasepool {
        // check app first run
        BOOL firstRun = [[AESharedResources sharedDefaults]
                         boolForKey:AEDefaultsFirstRunKey];
        
        if (firstRun) {
            _firstRunInProgress = YES;
        }
    }
}

//Finish long-running task
- (void)finishLongRunningTask{

#ifndef APP_EXTENSION
    
    dispatch_async(dispatch_get_main_queue(), ^{

        if (_reloadContentBlockingJsonLongTaskId != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:_reloadContentBlockingJsonLongTaskId];
            _reloadContentBlockingJsonLongTaskId = UIBackgroundTaskInvalid;
        }
    });
#endif
    
}

- (AESFilterConverter *)createConverterToJsonWithError:(NSError **)error {
    
    AESFilterConverter *converterToJSON = [AESFilterConverter new];
    if (!converterToJSON) {
        DDLogError(@"(AEService) Can't initialize converter to JSON format!");
        NSString *errorDescription = NSLocalizedString(@"Can't initialize converter to JSON format!", @"(AEService) Service errors descriptions");
        if (error != nil) {
            *error = [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_UNSUPPORTED_RULE userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
        }
    }
    return converterToJSON;
}

- (NSDictionary *)convertOneRule:(ASDFilterRule *)rule optimize:(BOOL)optimize error:(NSError **)error {

    NSDictionary *convertResult;
    NSError *err = nil;

    @autoreleasepool {

        do {
            AESFilterConverter *converterToJSON = [self createConverterToJsonWithError:&err];
            if (!converterToJSON) {
                break;
            }

            convertResult = [converterToJSON jsonFromRules:@[ rule ] upTo:1 optimize:optimize];
            err = convertResult[AESFConvertedErrorKey];
            if (err) {
                break;
            }

            if (![convertResult[AESFConvertedCountKey] boolValue] && [convertResult[AESErrorsCountKey] boolValue]) {

                NSString *errorDescription = NSLocalizedString(@"Cannot add the filter rule. Rule text is invalid.", @"(AEService) Service errors descriptions");
                err = [NSError errorWithDomain:AEServiceErrorDomain code:AES_ERROR_UNSUPPORTED_RULE userInfo:@{NSLocalizedDescriptionKey : errorDescription}];
                break;
            }
            
        } while (0);

    }

    if (err && error) {
        *error = err;
    }
    
    return convertResult;
}

@end
