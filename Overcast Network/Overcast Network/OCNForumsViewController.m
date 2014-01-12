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

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;]
    
    self.authorImages = [[NSMutableDictionary alloc] init];
    currentForum = [[Forum alloc] init];
    self.navigationController.title = currentForum.title;
    forumTopics = [[TopicParser alloc] init];
    [self refreshForumContent];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI:)
                                                 name:@"Update"
                                               object:nil];
    refreshing = false;
}

- (IBAction)refreshContent {
    if (!refreshing) {
        [self refreshForumContent];
        refreshing = true;
    }
}

- (void)refreshForumContent
{
    [self.refreshWheel beginRefreshing];
    if (self.tableView.contentOffset.y == 0) {
        [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
    }
    [forumTopics refreshTopicsWithURL:currentForum.url];
}

- (void)updateUI:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"Update"])
    {
        NSLog (@"Updating UI");
        NSLog(@"A total of %lu topics",(unsigned long)[forumTopics.topics count]);
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
        for (Topic *topic in forumTopics.topics) {
            dispatch_async(queue, ^(void) {
                int index = [forumTopics.topics indexOfObject:topic];
                NSString *author = topic.author;
                if (![self.authorImages objectForKey:author]) {
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ocnapp.maxsa.li/avatar.php?name=%@&size=48",author]]];
                    UIImage* image = [[UIImage alloc] initWithData:imageData];
                    if (image) {
                        NSIndexPath *rowToReload = [NSIndexPath indexPathForRow:index inSection:0];
                        NSArray *rowsToReload = [[NSArray alloc] initWithObjects:rowToReload, nil];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (!refreshing) {
                                [self.authorImages setObject:image forKey:author];
                                [self.tableView reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
                            }
                        });
                    }
                }
            });
        }
        [self.tableView reloadData];
        refreshing = false;
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
    return [forumTopics.topics count];
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
    return [[forumTopics.topics objectAtIndex:row] title];
}

- (NSString *)getAuthorForRow:(NSUInteger)row
{
    return [[forumTopics.topics objectAtIndex:row] author];
}

- (UIColor *)getColorForRow:(NSUInteger)row
{
    if ([[[forumTopics.topics objectAtIndex:row] rank] isEqualToString:@"mod"]) {
        return [UIColor redColor];
    }
    return [UIColor blackColor];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Topic"]) {
        OCNTopicViewController *topicViewController = (OCNTopicViewController *)segue.destinationViewController;
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"Topics"
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:nil
                                                                    action:nil];
        
        [self.navigationItem setBackBarButtonItem:backItem];
        topicViewController.topic = [forumTopics.topics objectAtIndex:[sender tag]];
        topicViewController.title = [[forumTopics.topics objectAtIndex:[sender tag]] title];
    }
    else if ([segue.identifier isEqualToString:@"Category"]) {
        UINavigationController *navigationController = [segue destinationViewController];
        CategoriesViewController *categoriesViewController = (CategoriesViewController *)([navigationController viewControllers][0]);
        categoriesViewController.currentForum = [[Forum alloc] init];
        categoriesViewController.currentForum.index = currentForum.index;
    }
}

- (void)unwind:(UIStoryboardSegue *)unwindSegue {
    CategoriesViewController *category = (CategoriesViewController *)unwindSegue.sourceViewController;
    currentForum = category.currentForum;
    
    self.navigationItem.title = currentForum.title;
    refreshing = true;
    [self refreshForumContent];
}

@end
