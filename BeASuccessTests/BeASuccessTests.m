//
//  BeASuccessTests.m
//  BeASuccessTests
//
//  Created by Tarpian Gabriel Lucian on 30/01/2017.
//  Copyright © 2017 Tarpian Gabriel Lucian. All rights reserved.
//

#import <XCTest/XCTest.h>

#include "DBManager.h"

@interface BeASuccessTests : XCTestCase

@end

@implementation BeASuccessTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// ################################# testNumberOfQuotes
- (void)testNumberOfQuotes
{
    XCTAssertEqual(400, [[DBManager getSharedInstance] getNumberOfQuotes]);
}

// ################################# testNumberOfAdvices
-(void)testNumberOfAdvices
{
    XCTAssertEqual(151, [[DBManager getSharedInstance] getNumberOfAdvices]);
}

// ################################# testQuotesValidity
-(void) testQuotesValidity
{
    BOOL quotes_valid = TRUE;
    
    int number_of_quotes = [[DBManager getSharedInstance] getNumberOfQuotes];
    
    for(int i = 1; i <= number_of_quotes; i++)
    {
        NSString *quote = [[DBManager getSharedInstance] getQuoteByID:i];
        NSString *author = [[DBManager getSharedInstance] getAuthorByID:i];
        NSString *category = [[DBManager getSharedInstance] getCategoryByID:i];
        
        if(quote.length == 0 || author.length == 0 || category.length == 0)
        {
            quotes_valid = FALSE;
            break;
        }
    }
    
    XCTAssertEqual(TRUE, quotes_valid);
}

// ################################# testAdvicesValidity
-(void) testAdvicesValidity
{
    BOOL advices_valid = TRUE;
    
    int number_of_advices = [[DBManager getSharedInstance] getNumberOfAdvices];
    for(int i = 1; i <= number_of_advices; i++)
    {
        NSString *advice = [[DBManager getSharedInstance] getAdviceByID:i];
        
        if(advice.length == 0)
        {
            advices_valid = FALSE;
            break;
        }
    }
    
    XCTAssertEqual(TRUE, advices_valid);
}

// ################################# testQuotesWallpapers
-(void) testQuotesWallpapers
{
    NSArray *categories = [NSArray arrayWithObjects:@"Education", @"Giving", @"Gratitude", @"Happiness", @"Health", @"Money", @"Success", @"Success2", @"Success3", nil];
    
    BOOL valid_categories = TRUE;
    int number_of_quotes = [[DBManager getSharedInstance] getNumberOfQuotes];
    
    for(int i = 1; i <= number_of_quotes; i++)
    {
        NSString *category = [[DBManager getSharedInstance] getCategoryByID:i];
        
        if( !([categories containsObject:category]) )
        {
            valid_categories = FALSE;
            break;
        }
    }
    
    XCTAssertEqual(TRUE, valid_categories);
}

@end
