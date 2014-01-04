//
//  Topic.h
//  Overcast Network
//
//  Created by Yichen Cao on 1/3/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIColor+Hex.h"

@interface Topic : NSObject

@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSString *topicID;
@property (nonatomic,strong) NSString *author;
@property (nonatomic,strong) UIColor *color;
@property (nonatomic,strong) NSDate *lastUpdated;

@end
