//
//  OCNTopicViewController.m
//  Overcast Network
//
//  Created by Yichen Cao on 3/25/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNTopicViewController.h"
#import "UIImage+RoundedCorner.h"
#import "OCNPostWebView.h"

@interface OCNTopicViewController ()

@property (nonatomic) BOOL refreshing;
@property (nonatomic,strong) NSUserDefaults *userDefaults;

@property (nonatomic,strong) PostParser *postParser;

@property (nonatomic,strong) NSMutableDictionary *heightsOfWebViews;

@property (nonatomic,strong) NSMutableArray *allPosts;
@property (nonatomic) int currentPage;
@property (nonatomic) int lastPage;
@property (nonatomic) BOOL denyGetNewSection;

@end

@implementation OCNTopicViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self refreshTopic];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.masterPopoverController presentPopoverFromBarButtonItem:self.navigationController.navigationBar.items[0]
                                         permittedArrowDirections:UIPopoverArrowDirectionUnknown
                                                         animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Lazy instantiation

- (PostParser *)postParser
{
    if (!_postParser) {
        _postParser = [[PostParser alloc] init];
    }
    return _postParser;
}

- (NSMutableDictionary *)heightsOfWebViews
{
    if (!_heightsOfWebViews) {
        _heightsOfWebViews = [[NSMutableDictionary alloc] init];
    }
    return _heightsOfWebViews;
}

- (NSMutableArray *)allPosts
{
    if (!_allPosts) {
        _allPosts = [[NSMutableArray alloc] init];
    }
    return _allPosts;
}

#pragma mark - Refreshing

- (IBAction)refreshPulled {
    if (self.topic) {
        if (!self.refreshing) {
            self.refreshing = YES;
            [self refreshTopic];
        }
    } else {
        [self.refreshControl endRefreshing];
    }
}

- (void)refreshTopic
{
    //Clear out old data, begin refreshing
    [self.refreshControl beginRefreshing];
    self.currentPage = 0;
    self.allPosts = nil;
    
    //Prep
    if (self.tableView.contentOffset.y == 0) {
        [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI:)
                                                 name:@"UpdatePosts"
                                               object:nil];
    [self.masterPopoverController dismissPopoverAnimated:YES];
    
    //Refresh
    NSURL *url = self.topic.topicURL;
    if (url != nil) {
        [self.postParser refreshPostsWithURL:[NSString stringWithFormat:@"%@",url]];
    }
}

- (void)getNewPage
{
    self.currentPage++;
    if (self.lastPage > self.currentPage) {
        [self.refreshControl beginRefreshing];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateUI:)
                                                     name:@"UpdatePosts"
                                                   object:nil];
        [self.postParser refreshPostsWithURL:[NSString stringWithFormat:@"%@?page=%i",self.topic.topicURL,(self.currentPage + 1)]];
    } else {
        self.currentPage--;
        NSLog(@"Last page bro");
    }
}

- (void)updateUI:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"UpdatePosts"]) {
        if (self.postParser.posts) {
            //Move all posts for page into array with pages, clear posts
            [self.allPosts addObject:self.postParser.posts];
            if (self.lastPage == 0) {
                self.lastPage = self.postParser.lastPage;
            }
            self.postParser.posts = nil;
            
            //Reload all data
            [self.tableView reloadData];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            NSLog(@"Updating page %i/%i with a total of %lu posts",(self.currentPage + 1),self.lastPage,(unsigned long)[self.allPosts[self.currentPage] count]);
            
            //Can get next page
            self.denyGetNewSection = NO;
            if (![self.userDefaults boolForKey:@"head_image_preference"]) {
                [self downloadAuthorImages];
            }
            //No longer refreshing content
            self.refreshing = false;
            [self.refreshControl endRefreshing];
        }
        else {
            self.currentPage--;
            self.denyGetNewSection = NO;
        }
    }
}

- (void)downloadAuthorImages
{
    dispatch_queue_t imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    for (Post *post in self.allPosts[self.currentPage]) {
        dispatch_async(imageQueue, ^(void) {
            NSString *author = post.author;
            if (![self.authorImages objectForKey:author]) {
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
                    });
                }
            }
        });
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.allPosts count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([self.allPosts count]) {
        return [self.allPosts[section] count];
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"Page %i",(section + 1)];
}

#define INDEX_PATH_KEY [NSString stringWithFormat:@"%i,%i",indexPath.section,indexPath.row]

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Post";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                            forIndexPath:indexPath];
    
    UIImageView *authorImage = (UIImageView *)[cell.contentView viewWithTag:1];
    UILabel *author = (UILabel *)[cell.contentView viewWithTag:2];
    UILabel *lastPosted = (UILabel *)[cell.contentView viewWithTag:3];
    OCNPostWebView *contentWebView = (OCNPostWebView *)[cell.contentView viewWithTag:4];
    

    NSString *authorName = [self getAuthorForIndexPath:indexPath];
    //If there is image, get image, else do nothing.
    if ([self.authorImages objectForKey:authorName]) {
        authorImage.image = [[self.authorImages objectForKey:authorName] imageWithRoundedCornersRadius:5];
    }
    
    //Get author name, color, last posted date
    author.text = [NSString stringWithFormat:@"%@%@",authorName,@""];
    author.textColor = [self getColorForIndexPath:indexPath];
    lastPosted.text = [self getLastPostedForIndexPath:indexPath];
    
    //Get content of post, check for height once, load HTML every time.
    [contentWebView setDelegate:nil];
    if (![self.heightsOfWebViews objectForKey:INDEX_PATH_KEY]) {
        [contentWebView setDelegate:self];
        contentWebView.scrollView.scrollEnabled = false;
        contentWebView.postIndex = indexPath;
    }
    [contentWebView loadHTMLString:[self getHTMLStringForIndexPath:indexPath] baseURL:nil];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self.heightsOfWebViews objectForKey:INDEX_PATH_KEY]) {
        return 100;
    } else {
        return 80 + [[self.heightsOfWebViews objectForKey:INDEX_PATH_KEY] intValue];
    }
}

#define WEB_VIEW_KEY [NSString stringWithFormat:@"%i,%i",webView.postIndex.section,webView.postIndex.row]

- (void)webViewDidFinishLoad:(OCNPostWebView *)webView
{
    if (![self.heightsOfWebViews objectForKey:WEB_VIEW_KEY]) {
        int height = [self checkHeightFromWebView:webView];
        [self.heightsOfWebViews setObject:[NSNumber numberWithInt:height]
                                forKey:WEB_VIEW_KEY];
    }
    [webView setHidden:NO];
    [self.tableView beginUpdates];
    NSIndexPath *rowToReload = [NSIndexPath indexPathForRow:webView.tag
                                                  inSection:0];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:rowToReload]
                          withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (int)checkHeightFromWebView:(UIWebView *)webView
{
    CGRect frame = webView.frame;
    frame.size.height = 1;
    webView.frame = frame;
    CGSize fittingSize = [webView sizeThatFits:CGSizeZero];
    frame.size = fittingSize;
    webView.frame = frame;
    return frame.size.height;
}

#pragma mark Accessory methods
- (NSString *)getAuthorForIndexPath:(NSIndexPath *)indexPath
{
    return [[self.allPosts[indexPath.section] objectAtIndex:indexPath.row] author];
}

- (UIColor *)getColorForIndexPath:(NSIndexPath *)indexPath
{
    NSString *rank = [[self.allPosts[indexPath.section] objectAtIndex:indexPath.row] rank];
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

- (NSString *)getLastPostedForIndexPath:(NSIndexPath *)indexPath
{
    return [[self.allPosts[indexPath.section] objectAtIndex:indexPath.row] lastPosted];
}

- (NSString *)getContentForIndexPath:(NSIndexPath *)indexPath
{
    return [[self.allPosts[indexPath.section] objectAtIndex:indexPath.row] content];
}

- (NSString *)getHTMLStringForIndexPath:(NSIndexPath *)indexPath
{
    NSString *HTMLString = [self getContentForIndexPath:indexPath];
    HTMLString = [NSString stringWithFormat:@"<font face='Helvetica' size='2'><p>%@</p>",HTMLString];
    //Add custom tags here!
    HTMLString = [HTMLString stringByReplacingOccurrencesOfString:@"<br/>" withString:@"<br>"];
    HTMLString = [HTMLString stringByReplacingOccurrencesOfString:@" Â " withString:@" "];
    HTMLString = [HTMLString stringByReplacingOccurrencesOfString:@"Â" withString:@""];
    HTMLString = [HTMLString stringByReplacingOccurrencesOfString:@"<img" withString:@"<img width=\"100%\""];
    HTMLString = [HTMLString stringByReplacingOccurrencesOfString:@"<(" withString:@"(< "];
    return HTMLString;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Table view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat height = scrollView.frame.size.height;
    CGFloat contentYoffset = scrollView.contentOffset.y;
    CGFloat distanceFromBottom = scrollView.contentSize.height - contentYoffset;
    
    if(distanceFromBottom <= height && !self.refreshing && [self.allPosts count] >= 1) {
        if (!self.denyGetNewSection) {
            self.denyGetNewSection = YES;
            [self getNewPage];
        }
    }
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)svc popoverController:(UIPopoverController *)pc willPresentViewController:(UIViewController *)aViewController
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Update"
                                                        object:self];
}

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Topics", @"Topics");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
