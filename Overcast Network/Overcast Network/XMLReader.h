//
//  XMLReader.h
//  Overcast Network
//
//  Created by Yichen Cao credits to troybrant.net on 1/11/14.
//  Copyright (c) 2014 Schem. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMLReader : NSObject <NSXMLParserDelegate> {
    @private
    NSMutableArray *dictionaryStack;
    NSMutableString *textInProgress;
}

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data;
+ (NSDictionary *)dictionaryForXMLString:(NSString *)string;

@end