//
//  OCNPostViewController.m
//  Overcast Network
//
//  Created by Yichen Cao on 4/18/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "OCNPostViewController.h"
#import "OCNReplyViewController.h"
#import "UIImage+Extras.h"
#import "OCNPostWebView.h"

@interface OCNPostViewController ()

@end

@implementation OCNPostViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImageView *authorImage = (UIImageView *)[self.view viewWithTag:1];
    UILabel *author = (UILabel *)[self.view viewWithTag:2];
    UILabel *lastPosted = (UILabel *)[self.view viewWithTag:3];
    OCNPostWebView *contentWebView = (OCNPostWebView *)[self.view viewWithTag:4];
    authorImage.image = [([OCNAuthorImages instance].authorImages)[self.post.author] imageWithRoundedCornersRadius:5];
    author.text = self.post.author;
    author.textColor = [UIColor colorForRank:self.post.rank];
    lastPosted.text = self.post.lastPosted;
    [contentWebView loadHTMLString:self.post.content baseURL:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sharePost:(id)sender
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
        [self openExternalURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://oc.tc/forums/posts/%@",self.post.postID]]];
    }
}

- (void)openExternalURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"Reply"]) {
        OCNReplyViewController *ocnrvc = [[segue.destinationViewController viewControllers] firstObject];
        ocnrvc.postURL = self.topicURL;
        ocnrvc.replyToID = self.post.postID;
        ocnrvc.navigationItem.title = [NSString stringWithFormat:@"@%@",self.post.author];
    }
}

@end
