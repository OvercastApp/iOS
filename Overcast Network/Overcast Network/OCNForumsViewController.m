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

@property (nonatomic) BOOL refreshing;
@property (nonatomic,strong) NSUserDefaults *settings;
@property (nonatomic,strong) TopicParser *forumTopics;
@property (nonatomic,strong) ForumParser *categoryParser;
@property (nonatomic,strong) Forum *currentForum;
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
    self.settings = [NSUserDefaults standardUserDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"Is hiding heads: %d | Source: %d",(int)[self.settings boolForKey:@"head_image_preference"],(int)[self.settings integerForKey:@"image_source_preference"]);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI:)
                                                 name:@"UpdateTopics"
                                               object:nil];
    [self refreshForumContent];
    self.refreshing = false;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Lazy instantiation

- (NSMutableDictionary *)authorImages
{
    if (!_authorImages) {
        _authorImages = [[NSMutableDictionary alloc] init];
    }
    return _authorImages;
}

- (OCNTopicViewController *)topicViewController
{
    if (!_topicViewController) {
        _topicViewController = [[OCNTopicViewController alloc] init];
        _topicViewController = (OCNTopicViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    }
    return _topicViewController;
}

- (Forum *)currentForum
{
    if (!_currentForum) {
        _currentForum = [[Forum alloc] init];
    }
    return _currentForum;
}

- (TopicParser *)forumTopics
{
    if (!_forumTopics) {
        _forumTopics = [[TopicParser alloc] init];
    }
    return _forumTopics;
}

- (ForumParser *)categoryParser
{
    if (!_categoryParser) {
        _categoryParser = [[ForumParser alloc] init];
    }
    return _categoryParser;
}

#pragma mark - Refreshing

- (IBAction)refreshContent
{
    if (!self.refreshing) {
        self.categoriesButton.enabled = false;
        self.refreshing = true;
        [self refreshForumContent];
    }
}

- (void)refreshForumContent
{
    [self.refreshWheel beginRefreshing];
    if (self.tableView.contentOffset.y == 0) {
        [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
    }
    [self.forumTopics refreshTopicsWithURL:self.currentForum.url];
    [self.categoryParser refreshForums];
}

- (void)updateUI:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"UpdateTopics"]) {
        NSLog(@"Updating UI with a total of %lu topics",(unsigned long)[self.forumTopics.topics count]);
        if (![self.settings boolForKey:@"head_image_preference"]) {
            dispatch_queue_t imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
            for (Topic *topic in self.forumTopics.topics) {
                dispatch_async(imageQueue, ^(void) {
                    int index = (int)[self.forumTopics.topics indexOfObject:topic];
                    NSString *author = topic.author;
                    if (![self.authorImages objectForKey:author]) {
                        NSString *sourceURL = [[NSString alloc] init];
                        switch ([self.settings integerForKey:@"image_source_preference"]) {
                            case 0:
                                sourceURL = [NSString stringWithFormat:@"http://ocnapp.maxsa.li/avatar.php?name=%@&size=48",author];
                                break;
                                
                            case 1:
                                sourceURL = [NSString stringWithFormat:@"https://avatar.oc.tc/%@/48.png",author];
                                break;
                        }
                        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:sourceURL]];
                        UIImage* image = [[UIImage alloc] initWithData:imageData];
                        if (image) {
                            NSIndexPath *rowToReload = [NSIndexPath indexPathForRow:index
                                                                          inSection:0];
                            NSArray *rowsToReload = [[NSArray alloc] initWithObjects:rowToReload, nil];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (!self.refreshing) {
                                    [self.authorImages setObject:image
                                                          forKey:author];
                                    [self.tableView reloadRowsAtIndexPaths:rowsToReload
                                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                                }
                            });
                        }
                    }
                });
            }
        }
        [self.tableView reloadData];
        self.refreshing = false;
        [self.refreshWheel endRefreshing];
        self.categoriesButton.enabled = true;
    }
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

#pragma mark Accessory methods

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
    if ([[[self.forumTopics.topics objectAtIndex:row] rank] isEqualToString:@"mod"]) {
        return [UIColor redColor];
    } else if ([[[self.forumTopics.topics objectAtIndex:row] rank] isEqualToString:@"admin"]) {
        return [UIColor orangeColor];
    } else if ([[[self.forumTopics.topics objectAtIndex:row] rank] isEqualToString:@"jrmod"]) {
        return [UIColor colorWithRed:1.0 green:0.5 blue:0.5 alpha:1.0];
    } else if ([[[self.forumTopics.topics objectAtIndex:row] rank] isEqualToString:@"srmod"]) {
        return [UIColor colorWithRed:0.5 green:0.0 blue:0.0 alpha:1.0];
    } else if ([[[self.forumTopics.topics objectAtIndex:row] rank] isEqualToString:@"dev"]) {
        return [UIColor purpleColor];
    }
    else return [UIColor blackColor];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.topicViewController.topic = [self.forumTopics.topics objectAtIndex:indexPath.row];
        self.topicViewController.title = [[self.forumTopics.topics objectAtIndex:indexPath.row] title];
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
        tvc.topic = [self.forumTopics.topics objectAtIndex:[sender tag]];
        tvc.title = [[self.forumTopics.topics objectAtIndex:[sender tag]] title];
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
        
        categoriesViewController.currentForum.index = self.currentForum.index;
        categoriesViewController.parsedContents = self.categoryParser.parsedContents;
    }
    NSLog(@"Segue prep done");
}

- (void)unwind:(UIStoryboardSegue *)unwindSegue
{
    CategoriesViewController *category = (CategoriesViewController *)unwindSegue.sourceViewController;
    self.currentForum = category.currentForum;
    
    self.navigationItem.title = self.currentForum.title;
    self.refreshing = true;
    [self refreshForumContent];
}

@end
