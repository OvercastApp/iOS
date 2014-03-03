//
//  OCNForumsViewController.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/3/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNForumsViewController.h"
#import "OCNTopicViewController.h"
#import "CategoriesViewController.h"
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
    
    self.authorImages = [[NSMutableDictionary alloc] init];
    self.navigationController.title = currentForum.title;
    self.topicViewController = [[OCNTopicViewController alloc] init];
    self.topicViewController = (OCNTopicViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    currentForum = [[Forum alloc] init];
    forumTopics = [[TopicParser alloc] init];
    categoryParser = [[ForumParser alloc] init];
    
    [self refreshForumContent];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI:)
                                                 name:@"Update"
                                               object:nil];
    refreshing = false;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Refreshing

- (IBAction)refreshContent
{
    if (!refreshing) {
        self.categoriesButton.enabled = false;
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
    [categoryParser refreshForums];
}

- (void)updateUI:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"Update"])
    {
        NSLog (@"Updating UI with a total of %lu topics",(unsigned long)[forumTopics.topics count]);
        settings = [NSUserDefaults standardUserDefaults];
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
        for (Topic *topic in forumTopics.topics) {
            dispatch_async(queue, ^(void) {
                int index = (int)[forumTopics.topics indexOfObject:topic];
                NSString *author = topic.author;
                if (![self.authorImages objectForKey:author]) {
                    NSString *sourceURL = [[settings stringForKey:@"image_source_preference"] isEqualToString:@"1"] ? [NSString stringWithFormat:@"http://ocnapp.maxsa.li/avatar.php?name=%@&size=48",author] : [NSString stringWithFormat:@"https://avatar.oc.tc/%@/48.png",author];
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:sourceURL]];
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
        self.categoriesButton.enabled = true;
    }
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
    } else if ([[[forumTopics.topics objectAtIndex:row] rank] isEqualToString:@"admin"]) {
        return [UIColor orangeColor];
    } else if ([[[forumTopics.topics objectAtIndex:row] rank] isEqualToString:@"jrmod"]) {
        return [UIColor colorWithRed:1.0 green:0.5 blue:0.5 alpha:1.0];
    } else if ([[[forumTopics.topics objectAtIndex:row] rank] isEqualToString:@"srmod"]) {
        return [UIColor colorWithRed:0.5 green:0.0 blue:0.0 alpha:1.0];
    } else if ([[[forumTopics.topics objectAtIndex:row] rank] isEqualToString:@"dev"]) {
        return [UIColor purpleColor];
    }
    else return [UIColor blackColor];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.topicViewController.topic = [forumTopics.topics objectAtIndex:indexPath.row];
        self.topicViewController.title = [[forumTopics.topics objectAtIndex:indexPath.row] title];
        [self.topicViewController refreshTopic];
    }
}

#pragma mark - Segue Preparation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"Category"]) {
        return self.categoriesPopover ? NO : YES;
    } else return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Prepare for OCNTopicViewController
    if ([segue.identifier isEqualToString:@"Topic"]) {
        OCNTopicViewController *tvc = (OCNTopicViewController *)segue.destinationViewController;
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"Topics"
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:nil
                                                                    action:nil];
        [self.navigationItem setBackBarButtonItem:backItem];
        tvc.topic = [forumTopics.topics objectAtIndex:[sender tag]];
        tvc.title = [[forumTopics.topics objectAtIndex:[sender tag]] title];
        tvc = self.topicViewController;
    }
    // Prepare for CategoriesViewController
    else if ([segue.identifier isEqualToString:@"Category"]) {
        CategoriesViewController *categoriesViewController = [[CategoriesViewController alloc] init];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            // Phone
            UINavigationController *navigationController = [segue destinationViewController];
            categoriesViewController = (CategoriesViewController *)([[navigationController viewControllers] firstObject]);
        } else {
            // Pad
            categoriesViewController = (CategoriesViewController *)segue.destinationViewController;
            UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
            self.categoriesPopover = popoverSegue.popoverController;
        }
        
        categoriesViewController.currentForum = [[Forum alloc] init];
        categoriesViewController.parsedContents = [[NSArray alloc] init];
        
        categoriesViewController.currentForum.index = currentForum.index;
        categoriesViewController.parsedContents = categoryParser.parsedContents;
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
