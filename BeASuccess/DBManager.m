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
    databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"BeASuccess5.db"]];
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
            const char *sqlStatementQuotes = "create table if not exists quotes(id integer primary key, author text, quote text, category text)";
            
            if(sqlite3_exec(database, sqlStatementQuotes,NULL,NULL, &errMsg ) != SQLITE_OK)
            {
                succes = NO;
                NSLog(@"Failed to create table \n");
                exit(-1);
            }
            
            const char *sqlStatementAdvices = "create table if not exists advices(id integer primary key, advice text)";
            if(sqlite3_exec(database, sqlStatementAdvices,NULL,NULL, &errMsg ) != SQLITE_OK)
            {
                succes = NO;
                NSLog(@"Failed to create table \n");
                exit(-2);
            }

            sqlite3_close(database);
            
            // populate the databases
            [self populateDatabaseQuotes];
            [self populateDatabaseAdvices];
            
            return succes;
        }
        else
        {
            succes = NO;
            NSLog(@"Failed to open/create database");
            exit(-3);
        }
    }
    return succes;
}

-(BOOL) insertDataQuote:(int)quoteId author:(NSString *)author quote:(NSString *)quote category:(NSString *)category
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

-(BOOL) insertDataAdvice:(int)adviceId advice:(NSString *)advice
{
    const char *dbPath = [databasePath UTF8String];
    
    // open the database then execute the statement that inserts the quote into it
    if( sqlite3_open(dbPath, &database) == SQLITE_OK )
    {
        NSString *insertSQL = [NSString stringWithFormat:@"insert into advices (id, advice) values (\"%d\",\"%@\")", adviceId, advice];
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

-(NSString*) getAdviceByID:(int)adviceId
{
    const char *dbPath = [databasePath UTF8String];
    
    // open the database then execute the statement
    if( sqlite3_open(dbPath, &database) == SQLITE_OK )
    {
        NSString *querySQL = [NSString stringWithFormat:@"select advice from advices where id = \"%d\"",adviceId];
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
                NSLog(@"Advice not found");
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

-(int) getNumberOfQuotes
{
    const char *dbPath = [databasePath UTF8String];
    
    // open the database then execute the statement
    if( sqlite3_open(dbPath, &database) == SQLITE_OK )
    {
        NSString *querySQL = [NSString stringWithFormat:@"select count(*) from quotes"];
        const char *queryStatement = [querySQL UTF8String];
        if( sqlite3_prepare_v2(database, queryStatement, -1, &statement, NULL) == SQLITE_OK)
        {
            // query was succesfully executed
            if( sqlite3_step(statement) == SQLITE_ROW)
            {
                int result = sqlite3_column_int(statement, 0);
                return result;
            }
            else
            {
                NSLog(@"Error when counting the quotes");
                return -1;
            }
        }
    }
    
    return -1;
}

-(int) getNumberOfAdvices
{
    const char *dbPath = [databasePath UTF8String];
    
    // open the database then execute the statement
    if( sqlite3_open(dbPath, &database) == SQLITE_OK )
    {
        NSString *querySQL = [NSString stringWithFormat:@"select count(*) from advices"];
        const char *queryStatement = [querySQL UTF8String];
        if( sqlite3_prepare_v2(database, queryStatement, -1, &statement, NULL) == SQLITE_OK)
        {
            // query was succesfully executed
            if( sqlite3_step(statement) == SQLITE_ROW)
            {
                int result = sqlite3_column_int(statement, 0);
                return result;
            }
            else
            {
                NSLog(@"Error when counting the quotes");
                return -1;
            }
        }
    }
    
    return -1;
}

-(BOOL) populateDatabaseQuotes
{
    bool boResult;
    
    // quote id = 1
    boResult = [self insertDataQuote:1
                         author:@"Mahatma Gandhi"
                          quote:@"Live as if you were to die tomorrow. Learn as if you were to live forever"
                       category:@"Education"];
    if(boResult == FALSE)
        return FALSE;

    // quote id = 2
    boResult = [self insertDataQuote:2
                         author:@"Bill Gates"
                          quote:@"I really had a lot of dreams when I was a kid, and I think a great deal of that grew out of the fact that I had a chance to read a lot"
                       category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 3
    boResult = [self insertDataQuote:3
                         author:@"Lorand Soares Szasz"
                          quote:@"Money run away from people who run after money"
                       category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 4
    boResult = [self insertDataQuote:4
                         author:@"Unknown"
                          quote:@"If you are willing to do more than you are paid to do, eventually you will be paid to do more than you do"
                       category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 5
    boResult = [self insertDataQuote:5
                         author:@"Albert Einstein"
                          quote:@"Try not to become a man of success. Rather become a man of value"
                       category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 6
    boResult = [self insertDataQuote:6
                         author:@"Dwayne Johnson"
                          quote:@"I'm always asked, 'What's the secret to success?' But there are no secrets. Be humble. Be hungry. And always be the hardest worker in the room"
                       category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 7
    boResult = [self insertDataQuote:7
                         author:@"Erich Fromm"
                          quote:@"Not he who has much is rich, but he who gives much"
                       category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 8
    boResult = [self insertDataQuote:8
                         author:@"Christopher Reeve"
                          quote:@"Success is finding satisfaction in giving a little more than you take"
                       category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 9
    boResult = [self insertDataQuote:9
                         author:@"Jack Canfield"
                          quote:@"Gratitude is the single most important ingredient to live a successful and fulfilled life"
                       category:@"Gratitude"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 10
    boResult = [self insertDataQuote:10
                         author:@"Michelle Obama"
                          quote:@"We learned about gratitude and humility - that so many people had a hand in our success, from the teachers who inspired us to the janitors who kept our school clean... and we were taught to value everyone's contribution and treat everyone with respect"
                       category:@"Gratitude"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 11
    boResult = [self insertDataQuote:11
                         author:@"Bonnie Blair"
                          quote:@"I never could have achieved the success that I have without setting physical activity and health goals"
                       category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 12
    boResult = [self insertDataQuote:12
                         author:@"P. T. Barnum"
                          quote:@"The foundation of success in life is good health: that is the substratum fortune; it is also the basis of happiness. A person cannot accumulate a fortune very well when he is sick"
                       category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 13
    boResult = [self insertDataQuote:13
                         author:@"Herman Cain"
                          quote:@"Success is not the key to happiness. Happiness is the key to success. If you love what you are doing, you will be successful"
                       category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 14
    boResult = [self insertDataQuote:14
                         author:@"Sarah Hyland"
                          quote:@"I think success right now is not about how famous you are or how much you're getting paid, but it's more about if you're steadily working and you're happy with what you're doing"
                       category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;

    
    NSLog(@"Database successfully populated!\n");
    return TRUE;
}

-(BOOL) populateDatabaseAdvices
{
    bool boResult;
    
    // advice id = 1
    boResult = [self insertDataAdvice:1 advice:@"Be patient, great things don’t come easy!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 2
    boResult = [self insertDataAdvice:2 advice:@"You are doing great! Keep it up!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 3
    boResult = [self insertDataAdvice:3 advice:@"Everyday you are one step closer!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 4
    boResult = [self insertDataAdvice:4 advice:@"Be grateful for what you have!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 5
    boResult = [self insertDataAdvice:5 advice:@"You are on the right track! Keep going!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 6
    boResult = [self insertDataAdvice:6 advice:@"You are amazing! I am proud of you!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 7
    boResult = [self insertDataAdvice:7 advice:@"Keep striving! Don’t quit!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 8
    boResult = [self insertDataAdvice:8 advice:@"Love yourself! You are unique and wonderful in your own way!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 9
    boResult = [self insertDataAdvice:9 advice:@"Celebrate your achievements!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 10
    boResult = [self insertDataAdvice:10 advice:@"Dream big, work hard!"];
    if(boResult == FALSE)
        return FALSE;
    
    return TRUE;
}

@end
