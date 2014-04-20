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
#import "OCNAuthorImages.h"

@interface OCNForumsViewController ()

@property (nonatomic) BOOL refreshing;
@property (nonatomic,strong) NSUserDefaults *userDefaults;

@property (nonatomic,strong) TopicParser *topicParser;
@property (nonatomic,strong) ForumParser *categoryParser;
@property (nonatomic,strong) Forum *currentForum;

@property (nonatomic,strong) NSMutableArray *allTopics;
@property (nonatomic) int currentPage;
@property (nonatomic) BOOL denyGetNewSection;

@property (nonatomic) BOOL didShowLogin;

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
    
    [self clearOldData];
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSTimer scheduledTimerWithTimeInterval:2
                                     target:self
                                   selector:@selector(checkLogins)
                                   userInfo:nil
                                    repeats:NO];
    
    NSLog(@"Is hiding heads: %d | Source: %d",(int)[self.userDefaults boolForKey:@"head_image_preference"],(int)[self.userDefaults integerForKey:@"image_source_preference"]);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI:)
                                                 name:@"UpdateTopics"
                                               object:nil];
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
    if (!didLogin)
        [self performSegueWithIdentifier:@"Login" sender:self];
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
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            _topicViewController = (OCNTopicViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
        }
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

- (TopicParser *)topicParser
{
    if (!_topicParser) {
        _topicParser = [[TopicParser alloc] init];
    }
    return _topicParser;
}

- (ForumParser *)categoryParser
{
    if (!_categoryParser) {
        _categoryParser = [[ForumParser alloc] init];
    }
    return _categoryParser;
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
    self.categoryParser = nil;
    self.topicParser = nil;
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
    [self.topicParser refreshTopicsWithURL:self.currentForum.url];
    [self.categoryParser refreshForums];
}

- (void)getNewPage
{
    self.currentPage++;
    [self.refreshWheel beginRefreshing];
    [self.topicParser refreshTopicsWithURL:[NSString stringWithFormat:@"%@?page=%i",self.currentForum.url,(self.currentPage + 1)]];
}

- (void)updateUI:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"UpdateTopics"]) {
        if (self.topicParser.topics) {
            //Move all topics for page into array with pages, clear topics
            [self.allTopics addObject:self.topicParser.topics];
            self.topicParser.topics = nil;
            
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
}

- (void)downloadAuthorImages
{
    dispatch_queue_t imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    for (Topic *topic in self.allTopics[self.currentPage]) {
        NSString *author = topic.author;
        if (![self.authorImages objectForKey:author]) {
            dispatch_async(imageQueue, ^(void) {
                int index = (int)[self.allTopics[self.currentPage] indexOfObject:topic];
                int section = self.currentPage;
                NSString *sourceURL = [[NSString alloc] init];
                switch ([self.userDefaults integerForKey:@"image_source_preference"]) {
                    case 0:
                        sourceURL = [NSString stringWithFormat:MAXSALI_AVATAR,author];
                        break;
                        
                    case 1:
                        sourceURL = [NSString stringWithFormat:OCN_AVATAR,author];
                        break;
                }
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:sourceURL]];
                UIImage* image = [[UIImage alloc] initWithData:imageData];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.authorImages setObject:image
                                              forKey:author];
                        if (!self.refreshing) {
                            NSIndexPath *rowToReload = [NSIndexPath indexPathForRow:index
                                                                          inSection:section];
                            NSArray *rowsToReload = [[NSArray alloc] initWithObjects:rowToReload, nil];
                            [self.tableView reloadRowsAtIndexPaths:rowsToReload
                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                        }
                    });
                }
            });
        }
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
    return [NSString stringWithFormat:@"Page %i",(section + 1)];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Forum Topic Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if ([self.allTopics count]) {
        NSString *author = [[self.allTopics[indexPath.section] objectAtIndex:indexPath.row] author];
        NSString *title = [[self.allTopics[indexPath.section] objectAtIndex:indexPath.row] title];
        if (![self.userDefaults boolForKey:@"head_image_preference"]) {
            if ([self.authorImages objectForKey:author]) {
                UIImage *image = [self.authorImages objectForKey:author];
                cell.imageView.image = [image imageWithRoundedCornersRadius:5];
            } else cell.imageView.image = [UIImage imageNamed:@"loading.png"];
            cell.tag = indexPath.row;
        }
        
        cell.textLabel.text = title;
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        
        cell.detailTextLabel.text = author;
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
        cell.detailTextLabel.textColor = [self getColorForIndexPath:indexPath];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

#pragma mark Accessory methods

- (UIColor *)getColorForIndexPath:(NSIndexPath *)indexPath
{
    NSString *rank = [[self.allTopics[indexPath.section] objectAtIndex:indexPath.row] rank];
    if ([rank isEqualToString:@"mod"]) {
        return [UIColor redColor];
    } else if ([rank isEqualToString:@"admin"]) {
        return [UIColor orangeColor];
    } else if ([rank isEqualToString:@"jrmod"]) {
        return [UIColor colorWithRed:1.0 green:0.5 blue:0.5 alpha:1.0];
    } else if ([rank isEqualToString:@"srmod"]) {
        return [UIColor colorWithRed:0.5 green:0.0 blue:0.0 alpha:1.0];
    } else if ([rank isEqualToString:@"dev"]) {
        return [UIColor purpleColor];
    }
    else return [UIColor blackColor];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.topicViewController.topic = [self.allTopics[indexPath.section] objectAtIndex:indexPath.row];
    self.topicViewController.title = [[self.allTopics[indexPath.section] objectAtIndex:indexPath.row] title];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.topicViewController.authorImages = self.authorImages;
        [self.topicViewController refreshTopic];
    } else {
        [self performSegueWithIdentifier:@"Topic" sender:self];
    }
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
    
    if(distanceFromBottom <= height && !self.refreshing && [self.allTopics count] >= 1) {
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
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:nil
                                                                    action:nil];
        [self.navigationItem setBackBarButtonItem:backItem];
        tvc.topic = self.topicViewController.topic;
        tvc.title = self.topicViewController.title;
        tvc.authorImages = self.authorImages;
    }
    // Prepare for CategoriesViewController
    else if ([segue.identifier isEqualToString:@"Category"]) {
        CategoriesViewController *categoriesViewController;
        
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
