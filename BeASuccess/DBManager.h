//
//  DBManager.h
//  BeASuccess
//
//  Created by Tarpian Gabriel Lucian on 30/01/2017.
//  Copyright © 2017 Tarpian Gabriel Lucian. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sqlite3.h>

@interface DBManager : NSObject
{
    NSString *databasePath;
}

// returns the instance of the database
+(DBManager*) getSharedInstance;

// creates the database
-(BOOL) createDB;

// insert data into database
-(BOOL) insertData:(int)quoteId author:(NSString*)author quote:(NSString*)quote category:(NSString*)category;

// populate the database
-(BOOL) populateDatabase;

// find the quote by id
-(NSString*) getQuoteByID:(int)quoteId;

// find the author by id
-(NSString*) getAuthorByID:(int)quoteId;

// find the author by id
-(NSString*) getCategoryByID:(int)quoteId;

@end
