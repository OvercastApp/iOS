//
//  OCNForumsViewController.m
//  Overcast Network
//
//  Created by Yichen Cao on 1/3/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNForumsViewController.h"
#import "CategoriesViewController.h"
#import "UIImage+Extras.h"
#import "OCNAuthorImages.h"

@interface OCNForumsViewController ()

@property (nonatomic) BOOL refreshing;
@property (nonatomic,strong) NSUserDefaults *userDefaults;

@property (nonatomic,strong) Forum *currentForum;
@property (nonatomic,strong) NSArray *forumParsedContents;

@property (nonatomic,strong) NSMutableArray *allTopics;
@property (nonatomic) int currentPage;
@property (nonatomic) BOOL denyGetNewSection;

@property (nonatomic) BOOL didShowLogin;

@property (nonatomic,strong) NSMutableDictionary *indexesToReload;

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
    
    self.clearsSelectionOnViewWillAppear = NO;
    [self clearOldData];
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSTimer scheduledTimerWithTimeInterval:2
                                     target:self
                                   selector:@selector(checkLogins)
                                   userInfo:nil
                                    repeats:NO];
    
    NSLog(@"Is hiding heads: %d | Source: %d",(int)[self.userDefaults boolForKey:@"head_image_preference"],(int)[self.userDefaults integerForKey:@"image_source_preference"]);
    [self refreshForumContent];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)checkLogins
{
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    BOOL didLogin = NO;
    for (NSHTTPCookie *each in [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://oc.tc"]]) {
        if ([each.name isEqualToString:@"remember_user_token"])
            didLogin = YES;
    }
//    if (!didLogin)
//        [self performSegueWithIdentifier:@"Login" sender:self];
}

#pragma mark Lazy instantiation

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

- (NSMutableArray *)allTopics
{
    if (!_allTopics) {
        _allTopics = [[NSMutableArray alloc] init];
    }
    return _allTopics;
}

#pragma mark - Refreshing

- (void)clearOldData
{
    self.currentPage = 0;
    self.allTopics = nil;
    self.denyGetNewSection = YES;
}

- (IBAction)refreshContent
{
    if (!self.refreshing) {
        self.categoriesButton.enabled = NO;
        [self refreshForumContent];
    }
}

- (void)refreshForumContent
{
    //Clear old data
    [self clearOldData];
    
    //Begin refreshing
    self.refreshing = YES;
    [self.refreshWheel beginRefreshing];
    
    //Move top into view
    if (self.tableView.contentOffset.y >= 0)
        [self.tableView setContentOffset:CGPointMake(0, - self.tableView.contentInset.top)
                                animated:YES];
    
    //Refresh
    [TopicParser refreshTopicsWithURL:self.currentForum.url
                             delegate:self];
    [ForumParser refreshForumsWithDelegate:self];
}

- (void)getNewPage
{
    self.currentPage++;
    [self.refreshWheel beginRefreshing];
    [TopicParser refreshTopicsWithURL:[NSString stringWithFormat:@"%@?page=%i",self.currentForum.url,(self.currentPage + 1)]
                             delegate:self];
}

- (void)downloadAuthorImages
{
    if (!self.indexesToReload) {
        self.indexesToReload = [[NSMutableDictionary alloc] init];
    }
    for (Topic *topic in self.allTopics[self.currentPage]) {
        NSIndexPath *imageIndex = [NSIndexPath indexPathForRow:[self.allTopics[self.currentPage] indexOfObject:topic]
                                                     inSection:self.currentPage];
        NSMutableArray *authorIndex = (self.indexesToReload)[topic.author];
        if (authorIndex) {
            //Add an indexPath
            [authorIndex addObject:imageIndex];
            (self.indexesToReload)[topic.author] = authorIndex;
        } else {
            //Create an array with indexPath
            NSMutableArray *arrayOfAuthorindex = [NSMutableArray arrayWithObject:imageIndex];
            (self.indexesToReload)[topic.author] = arrayOfAuthorindex;
        }
        [[OCNAuthorImages instance] getImageForAuthor:topic.author
                                               source:(int)[self.userDefaults integerForKey:@"image_source_preference"]];
        [OCNAuthorImages instance].delegate = self;
    }
}

#pragma mark - Topic Parser Delegate

- (void)receivedTopics:(NSMutableArray *)topics
{
    if (topics) {
        //Move all topics for page into array with pages, clear topics
        [self.allTopics addObject:topics];
        
        //Reload all data
        [self.tableView reloadData];
        NSLog(@"Updating page %i with a total of %lu topics",(self.currentPage + 1),(unsigned long)[self.allTopics[self.currentPage] count]);
        
        //Check if images needed
        if (![self.userDefaults boolForKey:@"head_image_preference"]) {
            [self downloadAuthorImages];
        }
        
        //Update extras
        self.categoriesButton.enabled = YES;
        self.denyGetNewSection = NO;
    }
    //No longer refreshing content
    self.refreshing = false;
    [self.refreshWheel endRefreshing];
    
}

#pragma mark Topic Parser Delegate

- (void)receivedForumsContents:(NSArray *)parsedContents
{
    self.forumParsedContents = parsedContents;
}

#pragma mark Author Images Delegate

- (void)imageFinishedLoadingForAuthor:(NSString *)author
{
    if (!self.refreshing) {
        //Check for out of bound indexes
        NSMutableArray *rowsToReload = (self.indexesToReload)[author];
        if (!rowsToReload) {
            return;
        }
        for (int index = 0; index < [rowsToReload count]; index++) {
            if (![self.tableView cellForRowAtIndexPath:rowsToReload[index]]) {
                [rowsToReload removeObjectAtIndex:index];
            }
        }
        //Reload rows
        [self.tableView reloadRowsAtIndexPaths:rowsToReload
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.indexesToReload removeObjectForKey:author];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.allTopics count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([self.allTopics count]) {
        return [self.allTopics[section] count];
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"Page %li",(long)(section + 1)];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Forum Topic Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if ([self.allTopics count]) {
        NSString *author = [(self.allTopics[indexPath.section])[indexPath.row] author];
        NSString *title = [(self.allTopics[indexPath.section])[indexPath.row] title];
        if (![self.userDefaults boolForKey:@"head_image_preference"]) {
            UIImage *authorImage = ([OCNAuthorImages instance].authorImages)[author];
            if (authorImage) {
                cell.imageView.image = [authorImage imageWithRoundedCornersRadius:5];
            } else {
                UIImage *steveImage = [UIImage imageNamed:@"Steve.png"];
                cell.imageView.image = [[UIImage imageWithImage:steveImage
                                                   scaledToSize:CGSizeMake(48, 48)] imageWithRoundedCornersRadius:5];
            }
            cell.tag = indexPath.row;
        }
        
        cell.textLabel.text = title;
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        
        cell.detailTextLabel.text = author;
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
        NSString *rank = [(self.allTopics[indexPath.section])[indexPath.row] rank];
        cell.detailTextLabel.textColor = [UIColor colorForRank:rank];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.topicViewController.topic = (self.allTopics[indexPath.section])[indexPath.row];
    self.topicViewController.title = [(self.allTopics[indexPath.section])[indexPath.row] title];
    [self.topicViewController refreshTopic];
    if (self.topicPopoverController) {
        [self.topicPopoverController dismissPopoverAnimated:YES];
    }
    self.topicViewController.lastPage = 0;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat height = scrollView.frame.size.height;
    CGFloat contentYoffset = scrollView.contentOffset.y;
    CGFloat distanceFromBottom = scrollView.contentSize.height - contentYoffset;
    
    if (distanceFromBottom <= height && !self.refreshing && [self.allTopics count] >= 1) {
        if (!self.denyGetNewSection) {
            self.denyGetNewSection = YES;
            [self getNewPage];
        }
    }
}

#pragma mark - Split view delegate

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc
{
    self.topicPopoverController = pc;
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.topicPopoverController = nil;
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
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:nil
                                                                    action:nil];
        [self.navigationItem setBackBarButtonItem:backItem];
        tvc.topic = self.topicViewController.topic;
        tvc.title = self.topicViewController.title;
    }
    // Prepare for CategoriesViewController
    else if ([segue.identifier isEqualToString:@"Category"]) {
        CategoriesViewController *categoriesViewController;
        
        categoriesViewController = (CategoriesViewController *)segue.destinationViewController;
        
        categoriesViewController.currentForum = [[Forum alloc] init];
        categoriesViewController.parsedContents = [[NSArray alloc] init];
        
        categoriesViewController.currentForum.index = self.currentForum.index;
        categoriesViewController.parsedContents = self.forumParsedContents;
    }
}

- (IBAction)unwindFromCategory:(UIStoryboardSegue *)unwindSegue
{
    CategoriesViewController *category = (CategoriesViewController *)unwindSegue.sourceViewController;
    self.currentForum = category.currentForum;
    
    self.navigationItem.title = self.currentForum.title;
    [self refreshForumContent];
}

- (IBAction)unwindFromLogin:(UIStoryboardSegue *)unwindSegue
{
    self.didShowLogin = YES;
}

@end
