//
//  OCNHTTPRequest.h
//  TestOCNLogin
//
//  Created by Yichen Cao on 4/16/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import "HTTPRequest.h"

@interface OCNHTTPRequest : HTTPRequest <NSURLConnectionDelegate>

+ (void)loginWithUsername:(NSString *)username password:(NSString *)password cookie:(NSString *)cookie sender:(id)sender;
+ (void)newTopic:(NSString *)topic content:(NSString *)content URL:(NSString *)url cookie:(NSString *)cookie sender:(id)sender;
+ (void)newPostWithContent:(NSString *)content URL:(NSString *)url cookie:(NSString *)cookie sender:(id)sender;
+ (void)newReplyToPost:(NSString *)postID WithContent:(NSString *)content URL:(NSString *)url cookie:(NSString *)cookie sender:(id)sender;

@end
