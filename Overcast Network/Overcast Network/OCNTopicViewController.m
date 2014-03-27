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

@property (nonatomic,strong) PostParser *postParser;
@property (nonatomic,strong) NSUserDefaults *settings;
@property (nonatomic,strong) NSMutableDictionary *arrayOfHeights;
@property (nonatomic,strong) NSMutableDictionary *didGetHeight;
@property (nonatomic) BOOL refreshing;

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
    self.settings = [NSUserDefaults standardUserDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"Is hiding heads: %d | Source: %d",(int)[self.settings boolForKey:@"head_image_preference"],(int)[self.settings integerForKey:@"image_source_preference"]);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI:)
                                                 name:@"UpdatePosts"
                                               object:nil];
    [self refreshTopic];
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

- (NSMutableDictionary *)authorImages
{
    if (!_authorImages) {
        _authorImages = [[NSMutableDictionary alloc] init];
    }
    return _authorImages;
}

- (NSMutableDictionary *)arrayOfHeights
{
    if (!_arrayOfHeights) {
        _arrayOfHeights = [[NSMutableDictionary alloc] init];
    }
    return _arrayOfHeights;
}

- (NSMutableDictionary *)didGetHeight
{
    if (!_didGetHeight) {
        _didGetHeight = [[NSMutableDictionary alloc] init];
    }
    return _didGetHeight;
}

- (void)refreshTopic
{
    if (!self.refreshing) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
        self.refreshing = true;
        NSURL *url = self.topic.topicURL;
        if (url != nil) {
            [self.postParser refreshPostsWithURL:[NSString stringWithFormat:@"%@",url]];
        }
    }
}

- (IBAction)refreshPulled {
    [self refreshTopic];
}

- (void)setRefreshing:(BOOL)refreshing
{
    _refreshing = refreshing;
    refreshing ? [self.refreshControl beginRefreshing] : [self.refreshControl endRefreshing];
}

- (void)updateUI:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"UpdatePosts"]) {
        [self.tableView reloadData];
        self.refreshing = false;
        NSLog(@"Updating UI with a total of %lu posts",(unsigned long)[self.postParser.posts count]);
        if (![self.settings boolForKey:@"head_image_preference"]) {
            dispatch_queue_t imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
            for (Post *post in self.postParser.posts) {
                dispatch_async(imageQueue, ^(void) {
                    int index = (int)[self.postParser.posts indexOfObject:post];
                    NSString *author = post.author;
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
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.postParser.posts count];
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
    
    if ([self.authorImages objectForKey:[self getAuthorForRow:indexPath.row]]) {
        authorImage.image = [[self.authorImages objectForKey:[self getAuthorForRow:indexPath.row]] imageWithRoundedCornersRadius:5];
    }
    author.text = [NSString stringWithFormat:@"%@%@",[self getAuthorForRow:indexPath.row],@""];
    author.textColor = [self getColorForRow:indexPath.row];
    lastPosted.text = [self getLastPostedForRow:indexPath.row];
    
    [contentWebView setDelegate:nil];
    if (![self.didGetHeight objectForKey:INDEX_PATH_KEY]) {
        [self.didGetHeight setObject:[NSNumber numberWithBool:YES]
                                forKey:INDEX_PATH_KEY];
        [contentWebView setDelegate:self];
        contentWebView.scrollView.scrollEnabled = false;
        contentWebView.postIndex = indexPath;
    }
    [contentWebView loadHTMLString:[self getHTMLString:indexPath.row] baseURL:nil];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self.arrayOfHeights objectForKey:INDEX_PATH_KEY]) {
        return 100;
    } else {
        return 85 + [[self.arrayOfHeights objectForKey:INDEX_PATH_KEY] intValue];
    }
}

#define WEB_VIEW_KEY [NSString stringWithFormat:@"%i,%i",webView.postIndex.section,webView.postIndex.row]

- (void)webViewDidFinishLoad:(OCNPostWebView *)webView
{
    NSLog(@"%@ finished loading :-)",WEB_VIEW_KEY);
    if (![self.arrayOfHeights objectForKey:WEB_VIEW_KEY]) {
        int height = [self checkHeightFromWebView:webView];
        [self.arrayOfHeights setObject:[NSNumber numberWithInt:height]
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
- (NSString *)getAuthorForRow:(NSUInteger)row
{
    return [[self.postParser.posts objectAtIndex:row] author];
}

- (UIColor *)getColorForRow:(NSUInteger)row
{
    if ([[[self.postParser.posts objectAtIndex:row] rank] isEqualToString:@"mod"]) {
        return [UIColor redColor];
    } else if ([[[self.postParser.posts objectAtIndex:row] rank] isEqualToString:@"admin"]) {
        return [UIColor orangeColor];
    } else if ([[[self.postParser.posts objectAtIndex:row] rank] isEqualToString:@"jrmod"]) {
        return [UIColor colorWithRed:1.0 green:0.5 blue:0.5 alpha:1.0];
    } else if ([[[self.postParser.posts objectAtIndex:row] rank] isEqualToString:@"srmod"]) {
        return [UIColor colorWithRed:0.5 green:0.0 blue:0.0 alpha:1.0];
    } else if ([[[self.postParser.posts objectAtIndex:row] rank] isEqualToString:@"dev"]) {
        return [UIColor purpleColor];
    }
    else return [UIColor blackColor];
}

- (NSString *)getLastPostedForRow:(NSUInteger)row
{
    return [[self.postParser.posts objectAtIndex:row] lastPosted];
}

- (NSString *)getContentForRow:(NSUInteger)row
{
    return [[self.postParser.posts objectAtIndex:row] content];
}

- (NSString *)getHTMLString:(NSUInteger)row
{
    NSString *HTMLString = [self getContentForRow:row];
    HTMLString = [NSString stringWithFormat:@"<font face='Helvetica' size='2'><p>%@</p>",HTMLString];
    //Add custom tags here!
    HTMLString = [HTMLString stringByReplacingOccurrencesOfString:@"<br/>" withString:@"<br>"];
    HTMLString = [HTMLString stringByReplacingOccurrencesOfString:@" Â " withString:@" "];
    HTMLString = [HTMLString stringByReplacingOccurrencesOfString:@"<img" withString:@"<img width=\"100%\""];
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
