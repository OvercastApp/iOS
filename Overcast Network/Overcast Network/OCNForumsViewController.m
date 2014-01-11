//
//  OCNForumsViewController.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/3/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNForumsViewController.h"
#import "OCNTopicViewController.h"
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
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
        for (Topic *topic in self.forumTopics.topics) {
            dispatch_async(queue, ^(void) {
                int index = [self.forumTopics.topics indexOfObject:topic];
                NSString *author = topic.author;
                if (![self.authorImages objectForKey:author]) {
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://avatar.oc.tc/%@/48.png",author]]];
                    UIImage* image = [[UIImage alloc] initWithData:imageData];
                    if (image) {
                        NSIndexPath *rowToReload = [NSIndexPath indexPathForRow:index inSection:0];
                        NSArray *rowsToReload = [[NSArray alloc] initWithObjects:rowToReload, nil];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.authorImages setObject:image forKey:author];
                            [self.tableView reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
                        });
                    }
                }
            });
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
    
    cell.imageView.image = nil;
    if ([self.authorImages objectForKey:[self getAuthorForRow:indexPath.row]]) {
        UIImage *image = [self.authorImages objectForKey:[self getAuthorForRow:indexPath.row]];
        cell.imageView.image = [image imageWithRoundedCornersRadius:5];
    }
    cell.tag = indexPath.row;
    
    cell.textLabel.text = [self getTitleForRow:indexPath.row];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@",[self getAuthorForRow:indexPath.row],@""];
    cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
    cell.detailTextLabel.textColor = [self getColorForRow:indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[OCNTopicViewController class]]) {
        OCNTopicViewController *topicViewController = (OCNTopicViewController *)segue.destinationViewController;
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"Topics"
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:nil
                                                                    action:nil];
        
        [self.navigationItem setBackBarButtonItem:backItem];
        topicViewController.topic = [self.forumTopics.topics objectAtIndex:[sender tag]];
        topicViewController.title = [[self.forumTopics.topics objectAtIndex:[sender tag]] title];
    }
}

@end
