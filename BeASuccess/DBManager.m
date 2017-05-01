//
//  DBManager.m
//  BeASuccess
//
//  Created by Tarpian Gabriel Lucian on 30/01/2017.
//  Copyright © 2017 Tarpian Gabriel Lucian. All rights reserved.
//

#import "DBManager.h"

static DBManager *sharedInstance = nil;
static sqlite3 *database = nil;
static sqlite3_stmt *statement = nil;

@implementation DBManager

// returns the instance of the database, only one instance available (Singleton Pattern used)
+(DBManager*) getSharedInstance
{
    if(sharedInstance == nil)
    {
        sharedInstance = [[super allocWithZone:NULL] init];
        [sharedInstance createDB];
    }
    return sharedInstance;
}

// creation of the database
-(BOOL) createDB
{
    NSString *docsDir;
    NSArray *dirPaths;
    
    // get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    
    // build the path to the database file
    databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"BeASuccess4.db"]];
    BOOL succes = YES;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // check if the database already exists
    if([fileManager fileExistsAtPath:databasePath ] == NO)
    {
        const char *dbPath = [databasePath UTF8String];
        
        // open the database then execute the statement that creates it
        if(sqlite3_open(dbPath, &database) == SQLITE_OK)
        {
            char *errMsg;
            const char *sqlStatement = "create table if not exists quotes(id integer primary key, author text, quote text, category text)";
            
            if(sqlite3_exec(database, sqlStatement,NULL,NULL, &errMsg ) != SQLITE_OK)
            {
                succes = NO;
                NSLog(@"Failed to create table \n");
            }
            
            sqlite3_close(database);
            
            // populate the database
            [self populateDatabase];
            
            return succes;
        }
        else
        {
            succes = NO;
            NSLog(@"Failed to open/create database");
        }
    }
    return succes;
}

-(BOOL) insertData:(int)quoteId author:(NSString *)author quote:(NSString *)quote category:(NSString *)category
{
    const char *dbPath = [databasePath UTF8String];
    
    // open the database then execute the statement that inserts the quote into it
    if( sqlite3_open(dbPath, &database) == SQLITE_OK )
    {
        NSString *insertSQL = [NSString stringWithFormat:@"insert into quotes (id, author, quote, category) values (\"%d\",\"%@\",\"%@\",\"%@\")", quoteId, author, quote,category];
        const char *insertStatement = [insertSQL UTF8String];
        sqlite3_prepare_v2(database, insertStatement, -1, &statement, NULL);
        if( sqlite3_step(statement) == SQLITE_DONE )
        {
            return YES;
        }
        
        sqlite3_reset(statement);
    }
    
    return NO;
}

-(NSString*) getQuoteByID:(int)quoteId
{
    const char *dbPath = [databasePath UTF8String];
    
    // open the database then execute the statement
    if( sqlite3_open(dbPath, &database) == SQLITE_OK )
    {
        NSString *querySQL = [NSString stringWithFormat:@"select quote from quotes where id = \"%d\"",quoteId];
        const char *queryStatement = [querySQL UTF8String];
        NSString *result;
        if( sqlite3_prepare_v2(database, queryStatement, -1, &statement, NULL) == SQLITE_OK)
        {
            // query was succesfully executed
            if( sqlite3_step(statement) == SQLITE_ROW)
            {
                result = [[NSString alloc] initWithUTF8String:(const char*) sqlite3_column_text(statement, 0)];
                return result;
            }
            else
            {
                NSLog(@"Quote not found");
                return nil;
            }
        }
    }
    
    return nil;
}

-(NSString*) getAuthorByID:(int)quoteId
{
    const char *dbPath = [databasePath UTF8String];
    
    // open the database then execute the statement
    if( sqlite3_open(dbPath, &database) == SQLITE_OK )
    {
        NSString *querySQL = [NSString stringWithFormat:@"select author from quotes where id = \"%d\"",quoteId];
        const char *queryStatement = [querySQL UTF8String];
        NSString *result;
        if( sqlite3_prepare_v2(database, queryStatement, -1, &statement, NULL) == SQLITE_OK)
        {
            // query was succesfully executed
            if( sqlite3_step(statement) == SQLITE_ROW)
            {
                result = [[NSString alloc] initWithUTF8String:(const char*) sqlite3_column_text(statement, 0)];
                return result;
            }
            else
            {
                NSLog(@"Quote not found");
                return nil;
            }
        }
    }
    
    return nil;
}

-(NSString*) getCategoryByID:(int)quoteId
{
    const char *dbPath = [databasePath UTF8String];
    
    // open the database then execute the statement
    if( sqlite3_open(dbPath, &database) == SQLITE_OK )
    {
        NSString *querySQL = [NSString stringWithFormat:@"select category from quotes where id = \"%d\"",quoteId];
        const char *queryStatement = [querySQL UTF8String];
        NSString *result;
        if( sqlite3_prepare_v2(database, queryStatement, -1, &statement, NULL) == SQLITE_OK)
        {
            // query was succesfully executed
            if( sqlite3_step(statement) == SQLITE_ROW)
            {
                result = [[NSString alloc] initWithUTF8String:(const char*) sqlite3_column_text(statement, 0)];
                return result;
            }
            else
            {
                NSLog(@"Quote not found");
                return nil;
            }
        }
    }
    
    return nil;
}

-(BOOL) populateDatabase
{
    bool boResult;
    
    // quote id = 1
    boResult = [self insertData:1
                         author:@"Mahatma Gandhi"
                          quote:@"Live as if you were to die tomorrow. Learn as if you were to live forever"
                       category:@"Education"];
    if(boResult == FALSE)
        return FALSE;

    // quote id = 2
    boResult = [self insertData:2
                         author:@"Bill Gates"
                          quote:@"I really had a lot of dreams when I was a kid, and I think a great deal of that grew out of the fact that I had a chance to read a lot"
                       category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 3
    boResult = [self insertData:3
                         author:@"Lorand Soares Szasz"
                          quote:@"Money run away from people who run after money"
                       category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 4
    boResult = [self insertData:4
                         author:@"Unknown"
                          quote:@"If you are willing to do more than you are paid to do, eventually you will be paid to do more than you do"
                       category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 5
    boResult = [self insertData:5
                         author:@"Albert Einstein"
                          quote:@"Try not to become a man of success. Rather become a man of value"
                       category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 6
    boResult = [self insertData:6
                         author:@"Dwayne Johnson"
                          quote:@"I'm always asked, 'What's the secret to success?' But there are no secrets. Be humble. Be hungry. And always be the hardest worker in the room"
                       category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 7
    boResult = [self insertData:7
                         author:@"Erich Fromm"
                          quote:@"Not he who has much is rich, but he who gives much"
                       category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 8
    boResult = [self insertData:8
                         author:@"Christopher Reeve"
                          quote:@"Success is finding satisfaction in giving a little more than you take"
                       category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 9
    boResult = [self insertData:9
                         author:@"Jack Canfield"
                          quote:@"Gratitude is the single most important ingredient to live a successful and fulfilled life"
                       category:@"Gratitude"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 10
    boResult = [self insertData:10
                         author:@"Michelle Obama"
                          quote:@"We learned about gratitude and humility - that so many people had a hand in our success, from the teachers who inspired us to the janitors who kept our school clean... and we were taught to value everyone's contribution and treat everyone with respect"
                       category:@"Gratitude"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 11
    boResult = [self insertData:11
                         author:@"Bonnie Blair"
                          quote:@"I never could have achieved the success that I have without setting physical activity and health goals"
                       category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 12
    boResult = [self insertData:12
                         author:@"P. T. Barnum"
                          quote:@"The foundation of success in life is good health: that is the substratum fortune; it is also the basis of happiness. A person cannot accumulate a fortune very well when he is sick"
                       category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 13
    boResult = [self insertData:13
                         author:@"Herman Cain"
                          quote:@"Success is not the key to happiness. Happiness is the key to success. If you love what you are doing, you will be successful"
                       category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 14
    boResult = [self insertData:14
                         author:@"Sarah Hyland"
                          quote:@"I think success right now is not about how famous you are or how much you're getting paid, but it's more about if you're steadily working and you're happy with what you're doin"
                       category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;

    
    NSLog(@"Database successfully populated!\n");
    return TRUE;
}

@end
