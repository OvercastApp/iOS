//
//  CategoriesViewController.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/11/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "CategoriesViewController.h"
#import "XMLReader.h"

@interface CategoriesViewController ()

@end

@implementation CategoriesViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    parser = [[ForumParser alloc] init];
    [parser refreshForums];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI:)
                                                 name:@"UpdateForums"
                                               object:nil];
}

- (void) updateUI:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"UpdateForums"])
    {
        parsedContents = [[NSArray alloc] initWithArray:parser.parsedContents];
    }
    [self.tableView reloadData];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancel:(UIBarButtonItem *)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [parsedContents count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return 1;
    }
    return [[parsedContents objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Forum Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (indexPath.section == 0 && indexPath.row == 0) {
        cell.textLabel.text = @"What's New";
    }
    else {
        NSDictionary *sectionData = [parsedContents objectAtIndex:indexPath.section];
        cell.textLabel.text = [[[sectionData valueForKey:@"subforum"] objectAtIndex:indexPath.row] valueForKey:@"text"];
    }
    
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        self.currentForum.index = indexPath;
    }
    if (indexPath.row == self.currentForum.index.row && indexPath.section == self.currentForum.index.section) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    }
    return [[parsedContents objectAtIndex:section] valueForKey:@"name"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        self.currentForum.title = @"What's New";
        self.currentForum.url = [NSURL URLWithString:@"https://oc.tc/forums"];
    }
    else {
        NSDictionary *sectionData = [parsedContents objectAtIndex:indexPath.section];
        self.currentForum.title = [[[sectionData valueForKey:@"subforum"] objectAtIndex:indexPath.row] valueForKey:@"text"];
        self.currentForum.url = [[[sectionData valueForKey:@"subforum"] objectAtIndex:indexPath.row] valueForKey:@"link"];
    }
    if (!(indexPath.row == self.currentForum.index.row && indexPath.section == self.currentForum.index.section)) {
        NSArray *rowsToReload = [[NSArray alloc] initWithObjects:indexPath,self.currentForum.index,nil];
        [self.tableView reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    self.currentForum.index = indexPath;
    
    [self performSegueWithIdentifier:@"Unwind From Categories" sender:self];
}

@end