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
#import "ACommons/ACLang.h"
#import "ACommons/ACSystem.h"
#import "ACommons/ACNetwork.h"
#import "ADomain/ADomain.h"
#import "AppDelegate.h"
#import "ASDatabase/ASDatabase.h"
#import "AEService.h"
#import "AESAntibanner.h"
#import "AESFilterConverter.h"
#import "AEUIWelcomePagerDataSource.h"
#import "AEUIMainController.h"

#import "AESharedResources.h"

#define SAFARI_BUNDLE_ID                        @"com.apple.mobilesafari"
#define SAFARI_VC_BUNDLE_ID                     @"com.apple.SafariViewService"

NSString *AppDelegateStartedUpdateNotification = @"AppDelegateStartedUpdateNotification";
NSString *AppDelegateFinishedUpdateNotification = @"AppDelegateFinishedUpdateNotification";
NSString *AppDelegateFailuredUpdateNotification = @"AppDelegateFailuredUpdateNotification";
NSString *AppDelegateUpdatedFiltersKey = @"AppDelegateUpdatedFiltersKey";

typedef void (^AETFetchCompletionBlock)(UIBackgroundFetchResult);
typedef void (^AEDownloadsCompletionBlock)();

@interface AppDelegate (){
    
    AETFetchCompletionBlock _fetchCompletion;
    AEDownloadsCompletionBlock _downloadCompletion;
    AEUIWelcomePagerDataSource *_welcomePageSource;
    NSArray *_updatedFilters;
    
    BOOL _activateWithOpenUrl;
}

@end

@implementation AppDelegate

/////////////////////////////////////////////////////////////////////
#pragma mark Application Init
/////////////////////////////////////////////////////////////////////

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions{
    
    @autoreleasepool {
        
        //------------- Preparing for start application. Stage 1. -----------------
        
        // Registering standart Defaults
        NSDictionary * defs = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
        if (defs)
            [[AESharedResources sharedDefaults] registerDefaults:defs];
        
        // Init Logger
        [[ACLLogger singleton] initLogger:[AESharedResources sharedAppLogsURL]];
        
#if DEBUG
        [[ACLLogger singleton] setLogLevel:ACLLDebugLevel];
#endif
        
        DDLogInfo(@"Application started. Version: %@", [ADProductInfo buildVersion]);
        
        DDLogInfo(@"(AppDelegate) Preparing for start application. Stage 1.");
        
        _fetchCompletion = nil;
        _downloadCompletion = nil;
        _activateWithOpenUrl = NO;
        self.userDefaultsInitialized = NO;
        
        // Init database
        [[ASDatabase singleton] initDbWithURL:[[AESharedResources sharedResuorcesURL] URLByAppendingPathComponent:AE_PRODUCTION_DB]];
        
        //------------ Interface Tuning -----------------------------------
        self.window.backgroundColor = [UIColor whiteColor];
        
        UIPageControl *pageControl = [UIPageControl appearance];
        pageControl.backgroundColor = [UIColor whiteColor];
        pageControl.currentPageIndicatorTintColor = [UIColor grayColor];
        pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
        
        //----------- Set main navigation controller -----------------------
        if ([[AEService singleton] firstRunInProgress]) {
            
            [[AEService singleton] onReady:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self loadMainNavigationController];
                });
            }];
        }
        else{
            
            [self loadMainNavigationController];
        }
        
        return YES;
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //------------- Preparing for start application. Stage 2. -----------------
    DDLogInfo(@"(AppDelegate) Preparing for start application. Stage 2.");
    
    //------------ Subscribe to Antibanner notification -----------------------------
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(antibannerNotify:) name:ASAntibannerFailuredUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(antibannerNotify:) name:ASAntibannerFinishedUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(antibannerNotify:) name:ASAntibannerStartedUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(antibannerNotify:) name:ASAntibannerDidntStartUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(antibannerNotify:) name:ASAntibannerUpdateFilterRulesNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(antibannerNotify:) name:ASAntibannerUpdatePartCompletedNotification object:nil];
    
    //------------ Checking DB status -----------------------------
    ASDatabase *dbService = [ASDatabase singleton];
    if (dbService.error) {
        
        DDLogWarn(@"(AppDelegate) Stage 2. DB Error. Panic!");
        //        [self dbFailure];
    }
    else if (!dbService.ready){
        
        DDLogWarn(@"(AppDelegate) Stage 2. DB not ready.");
        [dbService addObserver:self forKeyPath:@"ready" options:NSKeyValueObservingOptionNew context:nil];
    }
    //--------------------- Start Services ---------------------------
    else{
        
        [[AEService singleton] start];
        DDLogInfo(@"(AppDelegate) Stage 2. Main service started.");
    }
    
    //--------------------- Processing User Notification Action ---------
    //        NSUserNotification *userNotification =
    //        aNotification.userInfo[NSApplicationLaunchUserNotificationKey];
    //        if (userNotification) {
    //            [self userNotificationCenter:nil
    //                 didActivateNotification:userNotification];
    //        }
    
    //---------------------- Set period for checking filters ---------------------
    [self setPeriodForCheckingFilters];
    DDLogInfo(@"(AppDelegate) Stage 2 completed.");
    
    return YES;
}

- (void)setPeriodForCheckingFilters{
    
    NSTimeInterval interval = AS_FETCH_UPDATE_STATUS_PERIOD;
    if (interval < UIApplicationBackgroundFetchIntervalMinimum) {
        interval = UIApplicationBackgroundFetchIntervalMinimum;
    }
    
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:interval];
    DDLogInfo(@"(AppDelegate) Set background fetch interval: %f", interval);
    
}

/////////////////////////////////////////////////////////////////////
#pragma mark Application Delegate Methods
/////////////////////////////////////////////////////////////////////


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    DDLogInfo(@"(AppDelegate) applicationWillResignActive.");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    DDLogInfo(@"(AppDelegate) applicationDidEnterBackground.");
    [AESharedResources synchronizeSharedDefaults];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    DDLogInfo(@"(AppDelegate) applicationWillEnterForeground.");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    DDLogInfo(@"(AppDelegate) applicationDidBecomeActive.");
    
    [[AEService singleton] onReady:^{
        
        [[[AEService singleton] antibanner] repairUpdateStateWithCompletionBlock:^{
            
            if (_activateWithOpenUrl) {
                _activateWithOpenUrl = NO;
                DDLogInfo(@"(AppDelegate - applicationDidBecomeActive) Update process did not start because app activated with open URL.");
                return;
            }
            
            if (AEService.singleton.antibanner.updatesRightNow) {
                DDLogInfo(@"(AppDelegate - applicationDidBecomeActive) Update process did not start because it is performed right now.");
                return;
            }
            
            //Entry point for updating of the filters
            if ([self checkAutoUpdateConditions]) {
                [self invalidateAntibanner:NO interactive:YES];
            }
        }];
        
    }];
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    DDLogInfo(@"(AppDelegate) applicationWillTerminate.");
    [AESharedResources synchronizeSharedDefaults];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler{
    @autoreleasepool {
        
        DDLogInfo(@"(AppDelegate) application perform Fetch.");
        
        if (_fetchCompletion) {
            
            // In this case we receive fetch event when previous event still not processed.
            DDLogInfo(@"(AppDelegate) Previous Fetch still not processed.");
            
            // handle new completion handler
            _fetchCompletion = completionHandler;
            
            return;
        }
        
        //Entry point for updating of the filters
        _fetchCompletion = completionHandler;
        
        BOOL checkResult = [self checkAutoUpdateConditions];
        
        [[AEService singleton] onReady:^{
            
            [[[AEService singleton] antibanner] repairUpdateStateWithCompletionBlock:^{
                
                if (AEService.singleton.antibanner.updatesRightNow) {
                    DDLogInfo(@"(AppDelegate) Update process did not start because it is performed right now.");
                    return;
                }
                
                
                if (!checkResult) {
                    DDLogInfo(@"(AppDelegate - Background Fetch) Cancel fetch. App settings permit updates only over WiFi.");
                }
                
                if (!(checkResult && [self invalidateAntibanner:NO interactive:NO])){
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                    
                        if (_fetchCompletion) {
                            
                            DDLogInfo(@"(AppDelegate - Background Fetch) Call fetch Completion with result: failed.");
                            
                            _fetchCompletion(UIBackgroundFetchResultFailed);
                            _fetchCompletion = nil;
                        }
                    });
                }
            }];
        }];
    }
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(nonnull NSString *)identifier completionHandler:(nonnull void (^)())completionHandler {

    DDLogInfo(@"(AppDelegate) application handleEventsForBackgroundURLSession.");

    if ([identifier isEqualToString:AE_FILTER_UPDATES_ID]) {
        
        [[AEService singleton] onReady:^{

            _downloadCompletion = completionHandler;
            [[[AEService singleton] antibanner] repairUpdateStateForBackground];
        }];
    }
    else{
        DDLogError(@"(AppDelegate) Uncknown background session id: %@", identifier);
        completionHandler();
    }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options{
    
    DDLogError(@"(AppDelegate) application Open URL.");
    
    _activateWithOpenUrl = YES;
    
    NSString *appBundleId = options[UIApplicationOpenURLOptionsSourceApplicationKey];
    if (([appBundleId isEqualToString:SAFARI_BUNDLE_ID]
         || [appBundleId isEqualToString:SAFARI_VC_BUNDLE_ID])
        && [url.scheme isEqualToString:AE_URLSCHEME]) {
        
        [[AEService singleton] onReady:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    
                    NSString *command = url.host;
                    NSString *path = [url.path substringFromIndex:1];
                    
                    if ([command isEqualToString:AE_URLSCHEME_COMMAND_ADD]) {
                        
                        UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
                        if (nav.viewControllers.count) {
                            AEUIMainController *main = nav.viewControllers[0];
                            if ([main isKindOfClass:[AEUIMainController class]]) {
                                
                                [main addRuleToUserFilter:path];
                            }
                            else{
                                
                                DDLogError(@"(AppDelegate) Can't add rule because mainController is not found.");
                            }
                        }
                    }
                }
                //
            });
        }];
        
        return YES;
    }
    return NO;
}

/////////////////////////////////////////////////////////////////////
#pragma mark Public Methods
/////////////////////////////////////////////////////////////////////

- (BOOL)invalidateAntibanner:(BOOL)fromUI interactive:(BOOL)interactive {
    
    @synchronized(self) {
        
        // Begin update process (Downloading step)
        
        NSDate *lastCheck = [[AESharedResources sharedDefaults]
                             objectForKey:AEDefaultsCheckFiltersLastDate];
        if (fromUI || !lastCheck ||
            ([lastCheck timeIntervalSinceNow] * -1) >=
            AS_CHECK_FILTERS_UPDATES_PERIOD) {
            
            if (fromUI) {
                DDLogInfo(@"(AppDelegate) Update process started from UI.");
            }
            else{
                DDLogInfo(@"(AppDelegate) Update process started by timer.");
            }
            
            [[[AEService singleton] antibanner] beginTransaction];
            DDLogInfo(@"(AppDelegate) Begin of the Update Transaction from - invalidateAntibanner.");
            
            BOOL result = [[[AEService singleton] antibanner] startUpdatingForced:fromUI interactive:interactive];
            
            if (! result) {
                DDLogInfo(@"(AppDelegate) Update process did not start because [antibanner startUpdatingForced] return NO.");
                [[[AEService singleton] antibanner] rollbackTransaction];
                DDLogInfo(@"(AppDelegate) Rollback of the Update Transaction from ASAntibannerDidntStartUpdateNotification.");
            }

            return result;
        }
        
        DDLogInfo(@"(AppDelegate) Update process NOT started by timer. Time period from previous update too small.");
        
        
        return NO;
    }
}

/////////////////////////////////////////////////////////////////////
#pragma mark Observing notifications
/////////////////////////////////////////////////////////////////////

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    // DB DELAYED READY
    ASDatabase * dbService = [ASDatabase singleton];
    if ([object isEqual:dbService]
        && [keyPath isEqualToString:@"ready"]
        && dbService.ready) {
        
        [dbService removeObserver:self forKeyPath:@"ready"];
        
        //--------------------- Start Services ---------------------------
        [[AEService singleton] start];
        DDLogInfo(@"(AppDelegate) DB service ready. Main service started.");
        
        return;
    }
    
    // Default processing
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

/////////////////////////////////////////////////////////////////////
#pragma mark Notifications observers
/////////////////////////////////////////////////////////////////////

- (void)antibannerNotify:(NSNotification *)notification {
    
    // Update filter rule
    if ([notification.name isEqualToString:ASAntibannerUpdateFilterRulesNotification]){
        
        BOOL background = (_fetchCompletion || _downloadCompletion);
        [[AEService singleton] reloadContentBlockingJsonASyncWithBackgroundUpdate:background completionBlock:^(NSError *error) {
            
            if (error) {
                
                [[[AEService singleton] antibanner] rollbackTransaction];
                DDLogInfo(@"(AppDelegate) Rollback of the Update Transaction from ASAntibannerUpdateFilterRulesNotification.");
                
                [self updateFailuredNotify];
                
                if (self.navigation.topViewController && [[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [ACSSystemUtils showSimpleAlertForController:self.navigation.topViewController withTitle: NSLocalizedString(@"Error", @"(AEUISubscriptionController) Alert title. When converting rules process finished in foreground updating.") message:NSLocalizedString(@"Filters cannot be loaded into Safari. Try to clear your rules and the whitelist, or change the set of used filters.", @"(AppDegelate) Alert message. When converting rules process finished in foreground updating.")];
                    });
                }
            }
            else{
                
                // Success antibanner updated from backend
                
                [[AESharedResources sharedDefaults] setObject:[NSDate date] forKey:AEDefaultsCheckFiltersLastDate];
                
                [[[AEService singleton] antibanner] endTransaction];
                DDLogInfo(@"(AppDelegate) End of the Update Transaction from ASAntibannerUpdateFilterRulesNotification.");
                
                [self updateFinishedNotify];
            }
        }];
    }
    // Update started
    else if ([notification.name
              isEqualToString:ASAntibannerStartedUpdateNotification]) {
        
        // turn on network activity indicator
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [self updateStartedNotify];
    }
    // Update did not start
    else if ([notification.name
              isEqualToString:ASAntibannerDidntStartUpdateNotification]) {
        
        if ([[[AEService singleton] antibanner] inTransaction]) {
            
            [[[AEService singleton] antibanner] rollbackTransaction];
            DDLogInfo(@"(AppDelegate) Rollback of the Update Transaction from ASAntibannerDidntStartUpdateNotification.");
        }
        
        // Special update case.
        [self callCompletionHandler:UIBackgroundFetchResultFailed];
    }
    // Update performed
    else if ([notification.name
              isEqualToString:ASAntibannerFinishedUpdateNotification]) {
        
        _updatedFilters = [notification userInfo][ASAntibannerUpdatedFiltersKey];
        
        [[AEService singleton] onReloadContentBlockingJsonComplete:^{
            
            if ([[[AEService singleton] antibanner] inTransaction]) {
                // Success antibanner updated from backend
                [[AESharedResources sharedDefaults] setObject:[NSDate date] forKey:AEDefaultsCheckFiltersLastDate];
                [[[AEService singleton] antibanner] endTransaction];
                DDLogInfo(@"(AppDelegate) End of the Update Transaction from ASAntibannerFinishedUpdateNotification.");
                
                [self updateFinishedNotify];
            }
            
            
            // Special update case (in background).
            [self callCompletionHandler:UIBackgroundFetchResultNewData];
        }];
        
        // turn off network activity indicator
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
    // Update failed
    else if ([notification.name
              isEqualToString:ASAntibannerFailuredUpdateNotification]) {
        
        if ([[[AEService singleton] antibanner] inTransaction]) {
            
            [[[AEService singleton] antibanner] rollbackTransaction];
            DDLogInfo(@"(AppDelegate) Rollback of the Update Transaction from ASAntibannerFailuredUpdateNotification.");
        }
        
        [self updateFailuredNotify];
        
        // Special update case.
        [self callCompletionHandler:UIBackgroundFetchResultFailed];
        
        // turn off network activity indicator
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
    else if ([notification.name
              isEqualToString:ASAntibannerUpdatePartCompletedNotification]){
        
        DDLogInfo(@"(AppDelegate) Antibanner update PART notification.");
        [self callCompletionHandler:UIBackgroundFetchResultNewData];
    }
}

/////////////////////////////////////////////////////////////////////
#pragma mark Update Manager methods (private)
/////////////////////////////////////////////////////////////////////

- (void)updateStartedNotify{
    
    [self callOnMainQueue:^{
        
        DDLogDebug(@"(AppDelegate) Started update process.");
        [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateStartedUpdateNotification object:self];
    }];
}

- (void)updateFailuredNotify{
    
    
    [self callOnMainQueue:^{
        
        DDLogDebug(@"(AppDelegate) Failured update process.");
        [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateFailuredUpdateNotification object:self];
        
    }];
    
}

- (void)updateFinishedNotify{
    
    [self callOnMainQueue:^{
        
        DDLogDebug(@"(AppDelegate) Finished update process.");
        NSArray *metas = @[];
        
        if (_updatedFilters) {
            metas = _updatedFilters;
            _updatedFilters = nil;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateFinishedUpdateNotification object:self userInfo:@{AppDelegateUpdatedFiltersKey: metas}];
    }];
}

- (void)callCompletionHandler:(UIBackgroundFetchResult)result{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (_fetchCompletion) {
            NSArray *resultName = @[
                                    @"NewData",
                                    @"NoData",
                                    @"Failed"];

            DDLogInfo(@"(AppDelegate - Background Fetch) Call fetch Completion. With result: %@", resultName[result]);
            _fetchCompletion(result);
            _fetchCompletion = nil;
        }
        else if (_downloadCompletion){
            
            DDLogInfo(@"(AppDelegate - Background update downloads) Call Completion.");
            _downloadCompletion();
            _downloadCompletion = nil;
        }
        
    });
}

/////////////////////////////////////////////////////////////////////
#pragma mark Helpper Methods (private)
/////////////////////////////////////////////////////////////////////

- (void)loadMainNavigationController {
    
    UIViewController *nav = [[self mainStoryborad]
                             instantiateViewControllerWithIdentifier:@"mainNavigationController"];
    
    if (nav) {
        
        [UIView transitionWithView:self.window
                          duration:0.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.window.rootViewController = nav;
                        }
                        completion:nil];
        return;
    }
    
    DDLogError(@"(AppDelegate) Can't load main navigation controller");
}

- (UIStoryboard *)mainStoryborad{
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *storyboardName = [bundle objectForInfoDictionaryKey:@"UIMainStoryboardFile"];
    return [UIStoryboard storyboardWithName:storyboardName bundle:bundle];
}

- (void)callOnMainQueue:(dispatch_block_t)block{
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
#pragma clang diagnostic pop
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    if (currentQueue == mainQueue) {
        block();
    }
    else{
        dispatch_sync(mainQueue, block);
    }
    
}

- (BOOL)checkAutoUpdateConditions {

    BOOL result = YES;
    
    if ([[AESharedResources sharedDefaults] boolForKey:AEDefaultsWifiOnlyUpdates]) {
        
        Reachability *reach = [Reachability reachabilityForInternetConnection];
        
        result = [reach isReachableViaWiFi];
        
        if (! result) {
            DDLogInfo(@"(AppDelegate - checkAutoUpdateConditions) App settings permit updates only over WiFi.");
        }
    }
    
    return result;
}

@end
