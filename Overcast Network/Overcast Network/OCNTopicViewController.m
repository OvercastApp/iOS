//
//  OCNTopicViewController.m
//  Overcast Network
//
//  Created by Yichen Cao on 3/25/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNTopicViewController.h"
#import "OCNReplyViewController.h"

#import "UIImage+Extras.h"
#import "NSMutableArray+ReverseArray.h"
#import "OCNPostWebView.h"
#import "UIWebView+CheckHeight.h"

@interface OCNTopicViewController ()

@property (nonatomic) BOOL refreshing;
@property (nonatomic,strong) NSUserDefaults *userDefaults;

@property (nonatomic,strong) NSMutableDictionary *webViewHeights;

@property (nonatomic,strong) NSMutableArray *allPosts;
@property (nonatomic) int currentPage;
@property (nonatomic) BOOL denyGetNewSection;
@property (nonatomic) BOOL reversed;

@property (nonatomic,strong) NSMutableDictionary *indexesToReload;

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
    
    self.clearsSelectionOnViewWillAppear = NO;
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (self.topic.topicURL)
        [self refreshTopic];
    self.refreshing = YES;
    self.navigationController.condensesBarsOnSwipe = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!self.topic)
        [self.masterPopoverController presentPopoverFromBarButtonItem:self.navigationController.navigationBar.items[0]
                                             permittedArrowDirections:UIPopoverArrowDirectionUnknown
                                                             animated:YES];
}

#pragma mark Lazy instantiation

- (NSMutableDictionary *)webViewHeights
{
    if (!_webViewHeights) {
        _webViewHeights = [[NSMutableDictionary alloc] init];
    }
    return _webViewHeights;
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
        self.refreshing = NO;
    }
}

- (void)setRefreshing:(BOOL)refreshing
{
    _refreshing = refreshing;
    if (refreshing) {
        [self.refreshControl beginRefreshing];
        //Move loading spinner into view
        [self.tableView setContentOffset:CGPointMake(0, - self.tableView.contentInset.top)
                                animated:YES];
    } else {
        [self.refreshControl endRefreshing];
        //Move down into content
        if (self.tableView.contentOffset.y < 0)
            [self.tableView setContentOffset:CGPointMake(0, 0 - self.refreshControl.frame.size.height)
                                    animated:YES];
    }
}

- (void)refreshTopic
{
    //Clear out old data, begin refreshing
    self.denyGetNewSection = YES;
    self.reverseButton.enabled = NO;
    self.webViewHeights = nil;
    self.currentPage = self.reversed ? self.lastPage: 0;
    self.allPosts = nil;
    
    //Set NotificationCenter
    [self.masterPopoverController dismissPopoverAnimated:YES];
    
    //Refresh
    if (self.currentPage)
        //Off by one
        [PostParser refreshPostsWithURL:[NSString stringWithFormat:@"%@?page=%i",self.topic.topicURL,(self.currentPage + 1)] delegate:self];
    else
        [PostParser refreshPostsWithURL:self.topic.topicURL delegate:self];;
}

- (void)getNewPage
{
    self.currentPage += self.reversed ? -1 : 1;
    
    BOOL islastPage;
    if (self.reversed)
        islastPage = (self.currentPage < 0);
    else
        islastPage = (self.currentPage > self.lastPage);
    
    if (!islastPage) {
        [PostParser refreshPostsWithURL:[NSString stringWithFormat:@"%@?page=%i",self.topic.topicURL,(self.currentPage + 1)] delegate:self];
    } else {
        self.currentPage += self.reversed ? 1 : -1;
        NSLog(@"Reached end of thread");
    }
}

- (NSArray *)currentPagePosts
{
    return self.reversed ? self.allPosts[(self.lastPage - self.currentPage)] : self.allPosts[self.currentPage];
}

- (void)downloadAuthorImages
{
    if (!self.indexesToReload) {
        self.indexesToReload = [[NSMutableDictionary alloc] init];
    }
    for (Post *post in [self currentPagePosts]) {
        NSIndexPath *imageIndex = [NSIndexPath indexPathForRow:[[self currentPagePosts] indexOfObject:post]
                                                     inSection:self.currentPage];
        NSMutableArray *authorIndex = (self.indexesToReload)[post.author];
        if (authorIndex) {
            //Add an indexPath
            [authorIndex addObject:imageIndex];
            (self.indexesToReload)[post.author] = authorIndex;
        } else {
            //Create an array with indexPath
            NSMutableArray *arrayOfAuthorindex = [NSMutableArray arrayWithObject:imageIndex];
            (self.indexesToReload)[post.author] = arrayOfAuthorindex;
        }
        [[OCNAuthorImages instance] getImageForAuthor:post.author
                                               source:[self.userDefaults integerForKey:@"image_source_preference"]];
        [OCNAuthorImages instance].delegate = self;
    }
}

#pragma mark - Post Parser Delegate

- (void)receivedPosts:(NSMutableArray *)posts lastPage:(int)lastPage
{
    if (posts) {
        [self.navigationController setToolbarHidden:NO animated:YES];
        self.reverseButton.enabled = YES;
        
        //Move all posts for page into array with pages, clear posts
        if (self.reversed)
            [posts reverseArray];
        [self.allPosts addObject:posts];
        
        //Set last page
        if (self.lastPage == 0)
            //Off by one
            self.lastPage = lastPage - 1;
        
        //Reload all data
        [self.tableView reloadData];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        NSLog(@"Updating page %i/%i with a total of %lu posts",self.currentPage,self.lastPage,(unsigned long)[[self currentPagePosts] count]);
        
        //Can get next page
        self.denyGetNewSection = NO;
        if (![self.userDefaults boolForKey:@"head_image_preference"]) {
            [self downloadAuthorImages];
        } else {
            self.currentPage--;
            self.denyGetNewSection = NO;
        }
        //No longer refreshing content
        self.refreshing = NO;
    }
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
            //Check for bad reloads
            BOOL remove = NO;
            if (!([self.allPosts count] > [rowsToReload[index] section])) remove = YES;
            else if (!([self.allPosts[[rowsToReload[index] section]] count] > [rowsToReload[index] row])) remove = YES;
            if (remove) {
                [rowsToReload removeObjectAtIndex:index];
            }
        }
        //Reload rows
        [self.tableView reloadRowsAtIndexPaths:rowsToReload
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.indexesToReload removeObjectForKey:author];
    }
}

#pragma mark - Reverse sort

- (IBAction)reverseOrder:(UIBarButtonItem *)sender
{
    if (!self.topic) {
        return;
    }
    self.refreshing = YES;
    self.denyGetNewSection = YES;
    if (self.reversed) {
        self.reverseButton.style = UIBarButtonItemStylePlain;
        self.reverseButton.tintColor = nil;
        self.reversed = NO;
    } else {
        self.reverseButton.style = UIBarButtonItemStyleDone;
        self.reverseButton.tintColor = [UIColor greenColor];
        self.reversed = YES;
    }
    [self refreshTopic];
}

- (void)reverseArrays
{
    [self.allPosts reverseArray];
    for (NSMutableArray *post in self.allPosts) {
        [post reverseArray];
    }
    NSRange rangeOfSections = NSMakeRange(0,[self.allPosts count]);
    NSIndexSet *sectionsToReload = [NSIndexSet indexSetWithIndexesInRange:rangeOfSections];
    [self.tableView reloadSections:sectionsToReload
                  withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Table view data source

#define INDEX_PATH_KEY [NSString stringWithFormat:@"%lu,%lu",(unsigned long)indexPath.section,(unsigned long)indexPath.row]
#define WEB_VIEW_KEY [NSString stringWithFormat:@"%lu,%lu",(unsigned long)webView.postIndex.section,(unsigned long)webView.postIndex.row]

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
    long currentPage = self.reversed ? self.lastPage - section: section;
    return [NSString stringWithFormat:@"Page %li",currentPage + 1];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == self.lastPage) {
        return self.reversed ? @"First page of thread" : @"Last page of thread";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Post";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                            forIndexPath:indexPath];
    
    if ([self.allPosts count]) {
        //Cast views
        UIImageView *authorImageView = (UIImageView *)[cell.contentView viewWithTag:1];
        UILabel *authorLabel = (UILabel *)[cell.contentView viewWithTag:2];
        UILabel *lastPostedLabel = (UILabel *)[cell.contentView viewWithTag:3];
        OCNPostWebView *contentWebView = (OCNPostWebView *)[cell.contentView viewWithTag:4];
        
        //Get post
        Post *post = (self.allPosts[indexPath.section])[indexPath.row];
        
        //If there is image, get image, else use loading image.
        NSString *authorName = post.author;
        if (![self.userDefaults boolForKey:@"head_image_preference"]) {
            UIImage *authorImage = ([OCNAuthorImages instance].authorImages)[authorName];
            if (authorImage) {
                authorImageView.image = [authorImage imageWithRoundedCornersRadius:5];
            } else {
                UIImage *steveImage = [UIImage imageNamed:@"Steve.png"];
                authorImageView.image = [[UIImage imageWithImage:steveImage
                                                scaledToSize:CGSizeMake(48, 48)] imageWithRoundedCornersRadius:5];
            }
        } else {
            [authorImageView removeFromSuperview];
        }
        
        //Get author name, color, last posted date
        authorLabel.text = authorName;
        authorLabel.textColor = [UIColor colorForRank:post.rank];
        lastPostedLabel.text = post.lastPosted;
        
        //Get content of post, check for height once, load HTML every time.
        if (!(self.webViewHeights)[INDEX_PATH_KEY]) {
            [contentWebView setDelegate:self];
            contentWebView.scrollView.scrollEnabled = false;
            contentWebView.postIndex = [indexPath copy];
        }
        if (![contentWebView isLoading]) {
            [contentWebView loadHTMLString:post.content baseURL:nil];
        }
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((self.webViewHeights)[INDEX_PATH_KEY]) {
        return 80 + [(self.webViewHeights)[INDEX_PATH_KEY] intValue];
    }
    return 100;
}

#pragma mark Tableview delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.reversed) {
        if (indexPath.section == [tableView numberOfSections] - 1 && indexPath.row == [tableView numberOfRowsInSection:[tableView numberOfSections] - 1]) {
            return;
        }
    } else {
        if (indexPath.section == 0 && indexPath.row == 0) {
            return;
        }
    }
    [self performSegueWithIdentifier:@"Post" sender:(self.allPosts[indexPath.section])[indexPath.row]];
}

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

#pragma mark - Webview delegate

- (void)webViewDidStartLoad:(OCNPostWebView *)webView
{
    webView.loads++;
}

- (void)webViewDidFinishLoad:(OCNPostWebView *)webView
{
    webView.loads--;
    if (!webView.loads && !(self.webViewHeights)[WEB_VIEW_KEY]) {
        (self.webViewHeights)[WEB_VIEW_KEY] = @([webView checkHeight]);
        [webView setHidden:NO];
        NSIndexPath *indexToRefresh = webView.postIndex;
        
        if (!indexToRefresh) return;
        if ([self.allPosts count] <= indexToRefresh.section) return;
        else if ([self.allPosts[indexToRefresh.section] count] <= indexToRefresh.row) return;
        
        [self.tableView reloadRowsAtIndexPaths:@[indexToRefresh]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked){
        
        NSURL *url = request.URL;
        [self openExternalURL:url];
        return NO;
    }
    return YES;
}

#pragma mark Accessory methods

- (void)openExternalURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"Reply"]) {
        OCNReplyViewController *ocnrvc = [[segue.destinationViewController viewControllers] firstObject];
        ocnrvc.postURL = self.topic.topicURL;
        ocnrvc.navigationItem.title = [NSString stringWithFormat:@"@%@",self.topic.author];
    }
    if ([segue.identifier isEqualToString:@"Post"]) {
        OCNPostViewController *ocnpvc = segue.destinationViewController;
        ocnpvc.post = sender;
        ocnpvc.navigationItem.title = ocnpvc.post.author;
        ocnpvc.topicURL = self.topic.topicURL;
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

- (IBAction)shareTopic:(id)sender
{
    UIActionSheet *shareSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:@"Open in Safari", @"Share", nil];
    [shareSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonPressed = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonPressed isEqualToString:@"Open in Safari"]) {
        [self openExternalURL:[NSURL URLWithString:self.topic.topicURL]];
    }
}

- (IBAction)unwindFromReply:(UIStoryboardSegue *)unwindSegue
{
    self.reversed = NO;
    [self reverseOrder:nil];
}

@end
