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
    BOOL is_database_open;
}

-(BOOL) openDatabase;
-(void) closeDatabase;

// returns the instance of the database
+(DBManager*) getSharedInstance;

// creates the database
-(BOOL) createDB;

// insert data into database
-(BOOL) insertDataQuote:(int)quoteId author:(NSString*)author quote:(NSString*)quote category:(NSString*)category;
-(BOOL) insertDataAdvice:(int)adviceId advice:(NSString*)advice;

// populate the database
-(BOOL) populateDatabaseQuotes;
-(BOOL) populateDatabaseAdvices;

// find the quote by id
-(NSString*) getQuoteByID:(int)quoteId;

// find the advice by id
-(NSString*) getAdviceByID:(int)adviceId;

// find the author by id
-(NSString*) getAuthorByID:(int)quoteId;

// find the author by id
-(NSString*) getCategoryByID:(int)quoteId;

-(int) getNumberOfAdvices;
-(int) getNumberOfQuotes;



@end
