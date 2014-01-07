//
//  OCNForumsViewController.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/3/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNForumsViewController.h"
#import "UIImage+RoundedCorner.h"

@interface OCNForumsViewController ()

@end

@implementation OCNForumsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;]
    
    self.forumTopics = [[OCNTopics alloc] init];
    self.authorImages = [[NSMutableDictionary alloc] init];
    [self.refreshWheel beginRefreshing];
    [self refreshForumContent];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI:)
                                                 name:@"Update"
                                               object:nil];
    self.refreshing = false;
}

- (IBAction)refreshContent {
    if (!self.isRefreshing) {
        [self refreshForumContent];
        self.refreshing = true;
    }
}

- (void)refreshForumContent
{
    [self.forumTopics refreshTopics];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) updateUI:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"Update"])
    {
        NSLog (@"Updating UI");
        NSLog(@"A total of %lu topics",(unsigned long)[self.forumTopics.topics count]);
        for (int index = (int)[self.forumTopics.topics count] - 1; index >= 10; index --) {
            NSString *thisAuthor = [[self.forumTopics.topics objectAtIndex:index] author];
            if (![self.authorImages objectForKey:thisAuthor]) {
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
                dispatch_async(queue, ^(void) {
                    NSString *thisNewAuthor = [[self.forumTopics.topics objectAtIndex:index] author];
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://avatar.oc.tc/%@/48.png",thisNewAuthor]]];
                    UIImage* image = [[UIImage alloc] initWithData:imageData];
                    if (image) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.authorImages setObject:imageData forKey:thisNewAuthor];
                        });
                    }
                });
            }
        }
        [self.tableView reloadData];
        self.refreshing = false;
        [self.refreshWheel endRefreshing];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.forumTopics.topics count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Forum Topic Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.tag = indexPath.row;
    cell.imageView.image = nil;
    cell.textLabel.text = [self getTitleForRow:indexPath.row];
    cell.detailTextLabel.text = [self getAuthorForRow:indexPath.row];
    cell.detailTextLabel.textColor = [self getColorForRow:indexPath.row];
    
    NSString *thisAuthor = [[self.forumTopics.topics objectAtIndex:indexPath.row] author];
    if ([self.authorImages objectForKey:thisAuthor]) {
        cell.imageView.image = [[[UIImage alloc]initWithData:[self.authorImages objectForKey:thisAuthor]] imageWithRoundedCornersRadius:5];
    }
    else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
        dispatch_async(queue, ^(void) {
            if (cell.tag == indexPath.row) {
                NSString *thisNewAuthor = [[self.forumTopics.topics objectAtIndex:indexPath.row] author];
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://avatar.oc.tc/%@/48.png",thisNewAuthor]]];
                UIImage* image = [[UIImage alloc] initWithData:imageData];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (cell.tag == indexPath.row) {
                            cell.imageView.image = [image imageWithRoundedCornersRadius:5];
                            [cell setNeedsLayout];
                            [self.authorImages setObject:imageData forKey:thisNewAuthor];
                        }
                    });
                }
            }
        });
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (NSString *)getTitleForRow:(NSUInteger)row
{
    return [[self.forumTopics.topics objectAtIndex:row] title];
}

- (NSString *)getAuthorForRow:(NSUInteger)row
{
    return [[self.forumTopics.topics objectAtIndex:row] author];
}

- (UIColor *)getColorForRow:(NSUInteger)row
{
    return [[self.forumTopics.topics objectAtIndex:row] color];
}

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
