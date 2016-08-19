/**
    This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
    Copyright © 2015-2016 Performix LLC. All rights reserved.
 
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

#import "APUIDnsRequestsController.h"
#import "ACommons/ACLang.h"
#import "AEUICommons.h"
#import "APVPNManager.h"
#import "APDnsRequest.h"
#import "APDnsResponse.h"
#import "APUIDnsLogRecord.h"
#import "APUIDnsRequestDetail.h"

@interface APUIDnsRequestsController ()

@property (strong, nonatomic) UISearchController *searchController;
@property NSMutableArray <APUIDnsLogRecord *> *logRecords;
@property NSArray <APUIDnsLogRecord *> *filteredLogRecords;

@end

@implementation APUIDnsRequestsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.logRecords = [NSMutableArray array];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    
    [self.refreshControl addTarget:self action:@selector(refreshLog:) forControlEvents:UIControlEventValueChanged];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return 0;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredLogRecords.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dnsRequestCell" forIndexPath:indexPath];

    NSInteger row = indexPath.row;
    NSArray *records = self.filteredLogRecords;
    if (row < records.count) {

        APUIDnsLogRecord *record = records[row];
        
        if (!record.representedObject.requests.count) {
            return nil;
        }
        
        cell.textLabel.text = record.text;
        cell.detailTextLabel.textColor = cell.textLabel.textColor = record.color;
        cell.detailTextLabel.text = record.detailText;
    }

    return cell;
}


#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    
    if ([identifier isEqualToString:@"dnsRequestDetail"]) {

        APDnsLogRecord *record = [self logRecordForSelectedRow];
        if (!(record.requests.count)) {
            return NO;
        }
    }
    
    return YES;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"dnsRequestDetail"]) {

        APUIDnsRequestDetail *destination = [segue destinationViewController];

        destination.logRecord = [self logRecordForSelectedRow];
    }
}

/////////////////////////////////////////////////////////////////////
#pragma mark  Search Bar Delegates

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController{
    
    NSString *searchString = self.searchController.searchBar.text;
    
    if ([NSString isNullOrEmpty:searchString]){
        
        self.filteredLogRecords = [self revertRecords:self.logRecords];
    }
    else {

        NSMutableArray *fileredReverted = [NSMutableArray new];
        //revert array
        [self.logRecords enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(APUIDnsLogRecord * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

            
            if ([obj.text contains:searchString caseSensitive:NO]) {
                [fileredReverted addObject:obj];
                return;
            }

            if ([obj.detailText contains:searchString caseSensitive:NO]) {
                
                [fileredReverted addObject:obj];
            }
        }];
        
        self.filteredLogRecords = fileredReverted;
    }
    
    [self.tableView reloadData];
}

/////////////////////////////////////////////////////////////////////
#pragma mark  Actions

- (IBAction)refreshLog:(id)sender {

    [self reloadData];
}

/////////////////////////////////////////////////////////////////////
#pragma mark - Helper Methods

- (void)reloadData {
    
    [self.refreshControl beginRefreshing];
    [[APVPNManager singleton] obtainDnsLogRecords:^(NSArray<APDnsLogRecord *> *records) {
        
        [self.logRecords removeAllObjects];
        for (APDnsLogRecord *item in records) {
            APUIDnsLogRecord *uiRecord = [[APUIDnsLogRecord alloc] initWithRecord:item];
            if (uiRecord) {
                [self.logRecords addObject:uiRecord];
            }
        }
        
        [self updateSearchResultsForSearchController:self.searchController];
        if (self.refreshControl.refreshing) {
            [self.refreshControl endRefreshing];
        }
    }];
}

- (NSArray *)revertRecords:(NSArray *)arr {

    NSMutableArray *reversed = [NSMutableArray arrayWithCapacity:arr.count];
    [arr enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [reversed addObject:obj];
    }];

    return reversed;
}

- (IBAction)clickClear:(id)sender {

    if ([[APVPNManager singleton] clearDnsRequestsLog]) {
        
        [self reloadData];
    }
}

- (APDnsLogRecord *)logRecordForSelectedRow{
    
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    if (path) {
        
        NSInteger row = path.row;
        NSArray *records = self.filteredLogRecords;
        
        if (row < records.count) {
            
            return [records[row] representedObject];
        }
    }
    
    return nil;
}

@end
