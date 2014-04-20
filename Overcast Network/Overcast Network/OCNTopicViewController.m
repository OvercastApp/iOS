//
//  OCNTopicViewController.m
//  Overcast Network
//
//  Created by Yichen Cao on 3/25/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNTopicViewController.h"
#import "OCNReplyViewController.h"
#import "OCNPostViewController.h"

#import "UIImage+RoundedCorner.h"
#import "NSMutableArray+ReverseArray.h"
#import "OCNPostWebView.h"
#import "UIWebView+CheckHeight.h"

@interface OCNTopicViewController ()

@property (nonatomic) BOOL refreshing;
@property (nonatomic,strong) NSUserDefaults *userDefaults;

@property (nonatomic,strong) PostParser *postParser;

@property (nonatomic,strong) NSMutableDictionary *webViewHeights;

@property (nonatomic,strong) NSMutableArray *allPosts;
@property (nonatomic) int currentPage;
@property (nonatomic) BOOL denyGetNewSection;
@property (nonatomic) BOOL reversed;

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
        [self.refreshControl endRefreshing];
    }
}

- (void)refreshTopic
{
    //Clear out old data, begin refreshing
    [self.refreshControl beginRefreshing];
    self.denyGetNewSection = YES;
    self.reverseButton.enabled = NO;
    self.webViewHeights = nil;
    self.currentPage = self.reversed ? self.lastPage - 1 : 0;
    self.allPosts = nil;
    
    //Move top into view
    if (self.tableView.contentOffset.y >= 0)
        [self.tableView setContentOffset:CGPointMake(0, - self.tableView.contentInset.top)
                                animated:YES];
    
    //Set NotificationCenter
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI:)
                                                 name:@"UpdatePosts"
                                               object:nil];
    [self.masterPopoverController dismissPopoverAnimated:YES];
    
    //Refresh
    if (self.topic.topicURL != nil) {
        if (self.currentPage) {
            [self.postParser refreshPostsWithURL:[NSString stringWithFormat:@"%@?page=%i",self.topic.topicURL,self.currentPage + 1]];
        } else {
            [self.postParser refreshPostsWithURL:[NSString stringWithFormat:@"%@",self.topic.topicURL]];
        }
    }
}

- (void)getNewPage
{
    self.currentPage += self.reversed ? -1 : 1;
    
    BOOL islastPage;
    if (self.reversed) {
        islastPage = (self.currentPage >= 0);
    } else {
        islastPage = (self.currentPage < self.lastPage);
    }
    
    if (islastPage) {
        [self.refreshControl beginRefreshing];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateUI:)
                                                     name:@"UpdatePosts"
                                                   object:nil];
        [self.postParser refreshPostsWithURL:[NSString stringWithFormat:@"%@?page=%i",self.topic.topicURL,(self.currentPage + 1)]];
    } else {
        self.currentPage += self.reversed ? 1 : -1;
        NSLog(@"Last page bro");
    }
}

- (NSArray *)currentPagePosts
{
    if (self.reversed) {
        return self.allPosts[(self.lastPage - self.currentPage - 1)];
    } else {
        return self.allPosts[self.currentPage];
    }
}

- (void)updateUI:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"UpdatePosts"]) {
        if (self.postParser.posts) {
            [self.navigationController setToolbarHidden:NO animated:YES];
            self.reverseButton.enabled = YES;
            //Move all posts for page into array with pages, clear posts
            if (self.reversed) {
                [self.postParser.posts reverseArray];
            }
            [self.allPosts addObject:self.postParser.posts];
            if (self.lastPage == 0) {
                self.lastPage = self.postParser.lastPage;
            }
            self.postParser.posts = nil;
            
            //Reload all data
            [self.tableView reloadData];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            NSLog(@"Updating page %i/%i with a total of %lu posts",(self.currentPage + 1),self.lastPage,(unsigned long)[[self currentPagePosts] count]);
            
            //Can get next page
            self.denyGetNewSection = NO;
            if (![self.userDefaults boolForKey:@"head_image_preference"]) {
                [self downloadAuthorImages];
            }
        }
        else {
            self.currentPage--;
            self.denyGetNewSection = NO;
        }
        //No longer refreshing content
        self.refreshing = NO;
        [self.tableView setContentOffset:CGPointMake(0, 0 - self.refreshControl.frame.size.height)
                                animated:YES];
        [self.refreshControl endRefreshing];
    }
}

- (void)downloadAuthorImages
{
    dispatch_queue_t imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    for (Post *post in [self currentPagePosts]) {
        NSString *author = post.author;
        if (![self.authorImages objectForKey:author]) {
            dispatch_async(imageQueue, ^(void) {
                int index = (int)[[self currentPagePosts] indexOfObject:post];
                int section = self.reversed ? self.lastPage - self.currentPage - 1 : self.currentPage;
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
                UIImage *image = [[UIImage alloc] initWithData:imageData];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.authorImages setObject:image
                                              forKey:author];
                        if (!self.refreshing) {
                            NSIndexPath *rowToReload = [NSIndexPath indexPathForRow:index
                                                                          inSection:section];
                            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:rowToReload];
                            
                            if (cell) {
                                NSArray *rowsToReload = [[NSArray alloc] initWithObjects:rowToReload, nil];
                                [self.tableView reloadRowsAtIndexPaths:rowsToReload
                                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                            }
                        }
                    });
                }
            });
        }
    }
}

#pragma mark - Reverse sort

- (IBAction)reverseOrder:(UIBarButtonItem *)sender
{
    self.denyGetNewSection = YES;
    if (self.reversed) {
        self.reverseButton.style = UIBarButtonItemStyleBordered;
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
    long currentPage = self.reversed ? self.lastPage - section : section + 1;
    return [NSString stringWithFormat:@"Page %li",currentPage];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section + 1 == self.lastPage) {
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
        UIImageView *authorImage = (UIImageView *)[cell.contentView viewWithTag:1];
        UILabel *author = (UILabel *)[cell.contentView viewWithTag:2];
        UILabel *lastPosted = (UILabel *)[cell.contentView viewWithTag:3];
        OCNPostWebView *contentWebView = (OCNPostWebView *)[cell.contentView viewWithTag:4];
        Post *post = [self.allPosts[indexPath.section] objectAtIndex:indexPath.row];
        
        //If there is image, get image, else use loading image.
        NSString *authorName = post.author;
        if (![self.userDefaults boolForKey:@"head_image_preference"]) {
            if ([self.authorImages objectForKey:authorName]) {
                authorImage.image = [[self.authorImages objectForKey:authorName] imageWithRoundedCornersRadius:5];
            } else authorImage.image = [[UIImage imageNamed:@"loading.png"] imageWithRoundedCornersRadius:5];
        } else {
            [authorImage removeFromSuperview];
        }
        
        //Get author name, color, last posted date
        author.text = authorName;
        author.textColor = [self getColorForRank:post.rank];
        lastPosted.text = post.lastPosted;
        
        //Get content of post, check for height once, load HTML every time.
        if (![self.webViewHeights objectForKey:INDEX_PATH_KEY]) {
            [contentWebView setDelegate:self];
            contentWebView.scrollView.scrollEnabled = false;
            contentWebView.postIndex = [indexPath copy];
        }
        [contentWebView stopLoading];
        [contentWebView loadHTMLString:post.content baseURL:nil];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.webViewHeights objectForKey:INDEX_PATH_KEY]) {
        return 80 + [[self.webViewHeights objectForKey:INDEX_PATH_KEY] intValue];
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
    [self performSegueWithIdentifier:@"Post" sender:[self.allPosts[indexPath.section] objectAtIndex:indexPath.row]];
}

#pragma mark - Webview delegate

- (void)webViewDidStartLoad:(OCNPostWebView *)webView
{
    webView.loads++;
}

- (void)webViewDidFinishLoad:(OCNPostWebView *)webView
{
    webView.loads--;
    if (!webView.loads && ![self.webViewHeights objectForKey:WEB_VIEW_KEY]) {
        [self.webViewHeights setObject:[NSNumber numberWithInt:[webView checkHeight]]
                                forKey:WEB_VIEW_KEY];
        [webView setHidden:NO];
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
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

- (UIColor *)getColorForRank:(NSString *)rank
{
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
        ocnpvc.authorImages = self.authorImages;
    }
}

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
    self.denyGetNewSection = YES;
    self.reverseButton.style = UIBarButtonItemStyleDone;
    self.reverseButton.tintColor = [UIColor greenColor];
    self.reversed = YES;
    [self refreshTopic];
}

@end
