//
//  Topic.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/3/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

@interface Topic : NSObject

@property (nonatomic,strong) NSString *subForum;
@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSString *topicURL;
@property (nonatomic,strong) NSString *author;
@property (nonatomic,strong) NSString *rank;
@property (nonatomic,strong) NSDate *lastUpdated;

@end
