//
//  OCNAuthorImages.h
//  Overcast Network
//
//  Created by Yichen Cao on 4/19/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AuthorImagesDelegate <NSObject>

- (void)imageFinishedLoadingForAuthor:(NSString *)author;

@end

@interface OCNAuthorImages : NSObject

@property (nonatomic, weak) id <AuthorImagesDelegate> delegate;
@property (nonatomic,strong) NSMutableDictionary *authorImages;

- (void)getImageForAuthor:(NSString *)author source:(int)source;

+ (OCNAuthorImages *)instance;

@end
