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
    databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"BeASuccess.db"]];
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
            const char *sqlStatement = "create table if not exists quotes(id integer primary key, author text, quote text)";
            
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

-(BOOL) insertData:(int)quoteId author:(NSString *)author quote:(NSString *)quote
{
    const char *dbPath = [databasePath UTF8String];
    
    // open the database then execute the statement that inserts the quote into it
    if( sqlite3_open(dbPath, &database) == SQLITE_OK )
    {
        NSString *insertSQL = [NSString stringWithFormat:@"insert into quotes (id, author, quote) values (\"%d\",\"%@\",\"%@\")", quoteId, author, quote];
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

-(BOOL) populateDatabase
{
    bool boResult;
    
    // quote id = 1 - 226
    boResult = [self insertData:226 author:@"Pele" quote:@"Success is no accident. It is hard work, perseverance, learning, studying, sacrifice and most of all, love of what you are doing or learning to do"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 2 - 202
    boResult = [self insertData:202 author:@"Herman Cain" quote:@"Success is not the key to happiness. Happiness is the key to success. If you love what you are doing, you will be successful"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 3 - 57
    boResult = [self insertData:57 author:@"Dhirubhai Ambani" quote:@"If you don’t build your dream, someone else will hire you to help them build theirs"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 4 - 310
    boResult = [self insertData:310 author:@"Colin Powell" quote:@"There are no secrets to success. It is the result of preparation, hard work, and learning from failure"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 5 - 71
    boResult = [self insertData:71 author:@"Winston Churchill" quote:@"Success consists of going from failure to failure without loss of enthusiasm"];
    if(boResult == FALSE)
        return FALSE;

    NSLog(@"Database successfully populated!\n");
    return TRUE;
}

@end
