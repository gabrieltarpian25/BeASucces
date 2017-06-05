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
            if ([self populateDatabaseQuotes] == FALSE)
            {
                NSLog(@"# ERROR: Failed to populate the quotes database");
                exit(-4);
            }
            if([self populateDatabaseAdvices] == FALSE)
            {
                NSLog(@"# ERROR: Failed to populate the advices database");
                exit(-4);
            }
            return succes;
        }
        else
        {
            succes = NO;
            NSLog(@"# ERROR: Failed to open/create database");
            exit(-3);
        }
    }
    return succes;
}

-(BOOL) insertDataQuote:(int)quoteId author:(NSString *)author quote:(NSString *)quote category:(NSString *)category
{
    const char *dbPath = [databasePath UTF8String];
    
    __block bool success = NO;
    
    // open the database then execute the statement that inserts the quote into it
    if( sqlite3_open(dbPath, &database) == SQLITE_OK )
    {
        NSString *insertSQL = [NSString stringWithFormat:@"insert into quotes (id, author, quote, category) values (\"%d\",\"%@\",\"%@\",\"%@\")", quoteId, author, quote,category];
        const char *insertStatement = [insertSQL UTF8String];
        sqlite3_prepare_v2(database, insertStatement, -1, &statement, NULL);
        if( sqlite3_step(statement) == SQLITE_DONE )
        {
            success = YES;
        }
        sqlite3_reset(statement);
    }
    
    return success;
}

-(BOOL) insertDataAdvice:(int)adviceId advice:(NSString *)advice
{
    const char *dbPath = [databasePath UTF8String];
    
    __block bool success = NO;
    
    // open the database then execute the statement that inserts the quote into it
    if( sqlite3_open(dbPath, &database) == SQLITE_OK )
    {
        NSString *insertSQL = [NSString stringWithFormat:@"insert into advices (id, advice) values (\"%d\",\"%@\")", adviceId, advice];
        const char *insertStatement = [insertSQL UTF8String];
        sqlite3_prepare_v2(database, insertStatement, -1, &statement, NULL);
        if( sqlite3_step(statement) == SQLITE_DONE )
        {
            success = YES;
        }
        
        sqlite3_reset(statement);
    }
    
    return success;
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
                NSLog(@"# ERROR: Failed to retrieve quote %d from the database", quoteId);
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
                NSLog(@"# ERROR: Failed to retrieve advice %d from the database", adviceId);
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
                NSLog(@"# ERROR: Failed to retrieve Author of quote %d from database", quoteId);
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
                NSLog(@"# ERROR: failed to retrieve Category from database for quote %d",quoteId);
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
                NSLog(@"# ERROR: Failed to retrieve number of quotes from database");
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
                NSLog(@"# ERROR: Failed to retrieve number of advices from database");
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
                              author:@"Pele"
                               quote:@"Success is no accident. It is hard work, perseverance, learning, studying, sacrifice and most of all, love of what you are doing or learning to do"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 2
    boResult = [self insertDataQuote:2
                              author:@"Herman Cain"
                               quote:@"Success is not the key to happiness. Happiness is the key to success. If you love what you are doing, you will be successful"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 3
    boResult = [self insertDataQuote:3
                              author:@"Dhirubhai Ambani"
                               quote:@"If you don’t build your dream, someone else will hire you to help them build theirs"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 4
    boResult = [self insertDataQuote:4
                              author:@"Colin Powell"
                               quote:@"There are no secrets to success. It is the result of preparation, hard work, and learning from failure"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;

    // quote id = 5
    boResult = [self insertDataQuote:5
                              author:@"Winston Churchill"
                               quote:@"Success consists of going from failure to failure without loss of enthusiasm"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 6
    boResult = [self insertDataQuote:6
                              author:@"Albert Einstein"
                               quote:@"Try not to become a man of success. Rather become a man of value"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 7
    boResult = [self insertDataQuote:7
                              author:@"Karen Lamb"
                               quote:@"A year from now you may wish you had started today"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 8
    boResult = [self insertDataQuote:8
                              author:@"Earl Nightingale"
                               quote:@"We become what we think about most of the time, and that’s the strangest secret"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 9
    boResult = [self insertDataQuote:9
                              author:@"Richard Branson"
                               quote:@"Do not be embarrassed by your failures, learn from them and start again"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 10
    boResult = [self insertDataQuote:10
                              author:@"Pablo Picasso"
                               quote:@"Action is the foundational key to all success"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 11
    boResult = [self insertDataQuote:11
                              author:@"Albert Ellis"
                               quote:@"The best years of your life are the ones in which you decide your problems are your own. You do not blame them on your mother, the ecology, or the president. You realize that you control your own destiny"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 12
    boResult = [self insertDataQuote:12
                              author:@"George Lorimer"
                               quote:@"You’ve got to get up every morning with determination if you’re going to go to bed with satisfaction"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 13
    boResult = [self insertDataQuote:13
                              author:@"Lucille Ball"
                               quote:@"Love yourself first and everything else falls into line. You really have to love yourself to get anything done in this world"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 14
    boResult = [self insertDataQuote:14
                              author:@"Florence Nightingale"
                               quote:@"I attribute my success to this: I never gave or took any excuse"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 15
    boResult = [self insertDataQuote:15
                              author:@"Abraham Lincoln"
                               quote:@"Things may come to those who wait, but only the things left by those who hustle"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 16
    boResult = [self insertDataQuote:16
                              author:@"John R. Wooden"
                               quote:@"Don’t let what you cannot do interfere with what you can do"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 17
    boResult = [self insertDataQuote:17
                              author:@"George Bernard Shaw"
                               quote:@"Life isn’t about finding yourself. Life is about creating yourself"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 18
    boResult = [self insertDataQuote:18
                              author:@"Erich Fromm"
                               quote:@"Not he who has much is rich, but he who gives much"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 19
    boResult = [self insertDataQuote:19
                              author:@"George Sheehan"
                               quote:@"Success means having the courage, the determination, and the will to become the person you believe you were meant to be"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 20
    boResult = [self insertDataQuote:20
                              author:@"Benjamin Disraeli"
                               quote:@"The secret of success in life is for a man to be ready for his opportunity when it comes"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 21
    boResult = [self insertDataQuote:21
                              author:@"Unknown"
                               quote:@"Life’s real failure is when you do not realize how close you were to success when you gave up"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 22
    boResult = [self insertDataQuote:22
                              author:@"Mark Caine"
                               quote:@"The first step toward success is taken when you refuse to be a captive of the environment in which you first find yourself"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 23
    boResult = [self insertDataQuote:23
                              author:@"Harry F. Banks"
                               quote:@"For success, attitude is equally as important as ability"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 24
    boResult = [self insertDataQuote:24
                              author:@"Arthur Ashe"
                               quote:@"Start where you are. Use what you have. Do what you can"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 25
    boResult = [self insertDataQuote:25
                              author:@"Conrad Hilton"
                               quote:@"Success seems to be connected with action. Successful people keep moving. They make mistakes, but they don’t quit"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 26
    boResult = [self insertDataQuote:26
                              author:@"Oscar Wilde"
                               quote:@"What seems to us as bitter trials are often blessings in disguise"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 27
    boResult = [self insertDataQuote:27
                              author:@"Mark Victor Hansen"
                               quote:@"Don’t wait until everything is just right. It will never be perfect. There will always be challenges, obstacles and less than perfect conditions. So what. Get started now. With each step you take, you will grow stronger and stronger, more and more skilled, more and more self-confident and more and more successful"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 28
    boResult = [self insertDataQuote:28
                              author:@"Zig Ziglar"
                               quote:@"Your attitude, not your aptitude, will determine your altitude"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 29
    boResult = [self insertDataQuote:29
                              author:@"Kim Garst"
                               quote:@"If you don’t value your time, neither will others. Stop giving away your time and talents. Value what you know and start charging for it"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 30
    boResult = [self insertDataQuote:30
                              author:@"Bruce Lee"
                               quote:@"The successful warrior is the average man, with laser-like focus"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 31
    boResult = [self insertDataQuote:31
                              author:@"Mahatma Gandhi"
                               quote:@"Live as if you were to die tomorrow. Learn as if you were to live forever"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 32
    boResult = [self insertDataQuote:32
                              author:@"Alexander Graham Bell"
                               quote:@"Before anything else, preparation is the key to success"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 33
    boResult = [self insertDataQuote:33
                              author:@"Harriet Tubman"
                               quote:@"Every great dream begins with a dreamer. Always remember, you have within you the strength, the patience, and the passion to reach for the stars to change the world"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 34
    boResult = [self insertDataQuote:34
                              author:@"Thomas Jefferson"
                               quote:@"I find that the harder I work, the more luck I seem to have"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 35
    boResult = [self insertDataQuote:35
                              author:@"Jim Rohn"
                               quote:@"If you don’t design your own life plan, chances are you’ll fall into someone else’s plan. And guess what they have planned for you? Not much"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 36
    boResult = [self insertDataQuote:36
                              author:@"Robert Kiyosaki"
                               quote:@"Don’t let the fear of losing be greater than the excitement of winning"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 37
    boResult = [self insertDataQuote:37
                              author:@"David Bly"
                               quote:@"Striving for success without hard work is like trying to harvest where you haven’t planted"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 38
    boResult = [self insertDataQuote:38
                              author:@"Robert Collier"
                               quote:@"Success is the sum of small efforts, repeated day-in and day-out"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 39
    boResult = [self insertDataQuote:39
                              author:@"Michael Jordan"
                               quote:@"I’ve missed more than 9000 shots in my career. I’ve lost almost 300 games. 26 times, I’ve been trusted to take the game winning shot and missed. I’ve failed over and over and over again in my life. And that is why I succeed"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 40
    boResult = [self insertDataQuote:40
                              author:@"Napoleon Bonaparte"
                               quote:@"Take time to deliberate; but when the time for action arrives, stop thinking and go in"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 41
    boResult = [self insertDataQuote:41
                              author:@"Mark Twain"
                               quote:@"wenty years from now you will be more disappointed by the things that you didn’t do than by the ones you did do. So throw off the bowlines. Sail away from the safe harbor. Catch the trade winds in your sails. Explore. Dream. Discover"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 42
    boResult = [self insertDataQuote:42
                              author:@"Napoleon Hill"
                               quote:@"Patience, persistence and perspiration make an unbeatable combination for success"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 43
    boResult = [self insertDataQuote:43
                              author:@"Abraham Lincoln"
                               quote:@"If I had eight hours to chop down a tree, I’d spend six hours sharpening my ax"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 44
    boResult = [self insertDataQuote:44
                              author:@"Jim Rohn"
                               quote:@"If you are not willing to risk the usual, you will have to settle for the ordinary"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 45
    boResult = [self insertDataQuote:45
                              author:@"Martin Luther King, Jr"
                               quote:@"You don’t have to see the whole staircase, just take the first step"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 46
    boResult = [self insertDataQuote:46
                              author:@"Steve Jobs"
                               quote:@"Your work is going to fill a large part of your life, and the only way to be truly satisfied is to do what you believe is great work. And the only way to do great work is to love what you do. If you haven't found it yet, keep looking. Don't settle. As with all matters of the heart, you'll know when you find it"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 47
    boResult = [self insertDataQuote:47
                              author:@"Steve Jobs"
                               quote:@"We don't get a chance to do that many things, and every one should be really excellent. Because this is our life. Life is brief, and then you die, you know? And we've all chosen to do this with our lives. So it better be damn good. It better be worth it"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 48
    boResult = [self insertDataQuote:48
                              author:@"Steve Jobs"
                               quote:@"Be a yardstick of quality. Some people aren't used to an environment where excellence is expected"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 49
    boResult = [self insertDataQuote:49
                              author:@"Steve Jobs"
                               quote:@"You can't connect the dots looking forward; you can only connect them looking backward. So you have to trust that the dots will somehow connect in your future. You have to trust in something--your gut, destiny, life and karma, whatever. This approach has never let me down, and it has made all the difference in my life"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 50
    boResult = [self insertDataQuote:50
                              author:@"Steve Jobs"
                               quote:@"My favorite things in life don’t cost any money. It’s really clear that the most precious resource we all have is time"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    /*
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =
    boResult = [self insertDataQuote:
                              author:@""
                               quote:@""
                            category:@""];
    if(boResult == FALSE)
        return FALSE;
     */
    
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
    
    // advice id = 11
    boResult = [self insertDataAdvice:11 advice:@"Build good habits!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 12
    boResult = [self insertDataAdvice:12 advice:@"Take some rest, then start over!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 13
    boResult = [self insertDataAdvice:13 advice:@"Help a friend in need!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 14
    boResult = [self insertDataAdvice:14 advice:@"Celebrate other success!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 15
    boResult = [self insertDataAdvice:15 advice:@"Find a mentor and learn from him!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 16
    boResult = [self insertDataAdvice:16 advice:@"Everyday, learn something new in your field!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 17
    boResult = [self insertDataAdvice:17 advice:@"Take care of your health!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 18
    boResult = [self insertDataAdvice:18 advice:@"Do things that makes you happy!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 19
    boResult = [self insertDataAdvice:19 advice:@"Spend time with a children!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 20
    boResult = [self insertDataAdvice:20 advice:@"Before going to bed, write in your journal 3 things you are grateful for!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 21
    boResult = [self insertDataAdvice:21 advice:@"Give back! If you can’t give the gift of money, give the gift of time!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 22
    boResult = [self insertDataAdvice:22 advice:@"Embrace the change!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 23
    boResult = [self insertDataAdvice:23 advice:@"Step out of your comfort zone!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 24
    boResult = [self insertDataAdvice:24 advice:@"Don’t watch the news, they are full of negativity!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 25
    boResult = [self insertDataAdvice:25 advice:@"Compliment others!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 26
    boResult = [self insertDataAdvice:26 advice:@"Keep a journal!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 27
    boResult = [self insertDataAdvice:27 advice:@"You are the only responsible for your happiness!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 28
    boResult = [self insertDataAdvice:28 advice:@"What other people think of you is none of your business!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 29
    boResult = [self insertDataAdvice:29 advice:@"Make time to practice meditation and prayer!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 30
    boResult = [self insertDataAdvice:30 advice:@"Get some time off and play a game!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 31
    boResult = [self insertDataAdvice:31 advice:@"Make people smile everyday!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 32
    boResult = [self insertDataAdvice:32 advice:@"Don’t waste your precious energy on gossip!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 33
    boResult = [self insertDataAdvice:33 advice:@"Invest your energy in the positive present moment!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 34
    boResult = [self insertDataAdvice:34 advice:@"Forget the past, but don’t forget to learn from it!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 35
    boResult = [self insertDataAdvice:35 advice:@"Realise that life is a school and you are here to learn!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 36
    boResult = [self insertDataAdvice:36 advice:@"Smile and laugh more!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 37
    boResult = [self insertDataAdvice:37 advice:@"Don’t compare your life to others. You have no idea what their journey is all about!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 38
    boResult = [self insertDataAdvice:38 advice:@"Enjoy life’s each moment!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 39
    boResult = [self insertDataAdvice:39 advice:@"Love yourself!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 40
    boResult = [self insertDataAdvice:40 advice:@"The best is yet to come!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 41
    boResult = [self insertDataAdvice:41 advice:@"Spend some time alone regularly!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 42
    boResult = [self insertDataAdvice:42 advice:@"Use more positive words!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 43
    boResult = [self insertDataAdvice:43 advice:@"Spend time with people you love!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 44
    boResult = [self insertDataAdvice:44 advice:@"Remember you will always regret what you didn’t do rather than what you did!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 45
    boResult = [self insertDataAdvice:45 advice:@"Make each day count!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 46
    boResult = [self insertDataAdvice:46 advice:@"Your thoughts become what you are. What you think, you believe!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 47
    boResult = [self insertDataAdvice:47 advice:@"Keep moving forward, you will make it!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 48
    boResult = [self insertDataAdvice:48 advice:@"No step is too small, make one everyday!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 49
    boResult = [self insertDataAdvice:49 advice:@"Sometimes you win, sometimes you learn!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 50
    boResult = [self insertDataAdvice:50 advice:@"Time is the only thing you never get back!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 51
    boResult = [self insertDataAdvice:51 advice:@"Attitude is more important than talent!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 52
    boResult = [self insertDataAdvice:52 advice:@"It’s not that big of a deal if you’re imperfect, because everyone is!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 53
    boResult = [self insertDataAdvice:53 advice:@"Have the courage to follow your heart!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 54
    boResult = [self insertDataAdvice:54 advice:@"Realize how brave, strong and amazing you are!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 55
    boResult = [self insertDataAdvice:55 advice:@"Stop complaining and do something about it!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 56
    boResult = [self insertDataAdvice:56 advice:@"Fill your life with positivity and joy!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 57
    boResult = [self insertDataAdvice:57 advice:@"You attract what you are!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 58
    boResult = [self insertDataAdvice:58 advice:@"Know when to speak up, know when to stay quiet!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 59
    boResult = [self insertDataAdvice:59 advice:@"Stay away from toxic people!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 60
    boResult = [self insertDataAdvice:60 advice:@"Talk less, do more!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 61
    boResult = [self insertDataAdvice:61 advice:@"You are beautiful!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 62
    boResult = [self insertDataAdvice:62 advice:@"Put down your phone when you’re out with people!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 63
    boResult = [self insertDataAdvice:63 advice:@"Eat whole foods as much as possible!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 64
    boResult = [self insertDataAdvice:64 advice:@"Face your problems head on! They will be scared by you and disappear!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 65
    boResult = [self insertDataAdvice:65 advice:@"Always be honest!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 66
    boResult = [self insertDataAdvice:66 advice:@"You are ready for the next step!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 67
    boResult = [self insertDataAdvice:67 advice:@"Help those around you!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 68
    boResult = [self insertDataAdvice:68 advice:@"Never let success get to your head!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 69
    boResult = [self insertDataAdvice:69 advice:@"Never let failure get to your heart!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 70
    boResult = [self insertDataAdvice:70 advice:@"Keep your mind positive!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 71
    boResult = [self insertDataAdvice:71 advice:@"Empower others!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 72
    boResult = [self insertDataAdvice:72 advice:@"Focus only on one thing at a time!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 73
    boResult = [self insertDataAdvice:73 advice:@"Overcome fears, self-doubt and being too self-conscious!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 74
    boResult = [self insertDataAdvice:74 advice:@"Find the fun part in everything you do!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 75
    boResult = [self insertDataAdvice:75 advice:@"Invest your love, time and energy on things you want to do long term!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 76
    boResult = [self insertDataAdvice:76 advice:@"Get up early!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 77
    boResult = [self insertDataAdvice:77 advice:@"Nothing happens until you take action!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 78
    boResult = [self insertDataAdvice:78 advice:@"Starting is the hardest part, but even if you fail you will grow just from trying!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 79
    boResult = [self insertDataAdvice:79 advice:@"Take responsibility for your mistakes!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 80
    boResult = [self insertDataAdvice:80 advice:@"Be the most positive and enthusiastic person you know!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 81
    boResult = [self insertDataAdvice:81 advice:@"Be modest! A lot was accomplished before we were born!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 82
    boResult = [self insertDataAdvice:82 advice:@"Listen to podcasts!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 83
    boResult = [self insertDataAdvice:83 advice:@"Make time to exercise!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 84
    boResult = [self insertDataAdvice:84 advice:@"Don’t make excuses!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 85
    boResult = [self insertDataAdvice:85 advice:@"What happens tomorrow is because of how you think, what you say and what you do today!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 86
    boResult = [self insertDataAdvice:86 advice:@"Your time is limited, use it wisely!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 87
    boResult = [self insertDataAdvice:87 advice:@"Everything will workout!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 88
    boResult = [self insertDataAdvice:88 advice:@"Do what scares you!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 89
    boResult = [self insertDataAdvice:89 advice:@"Your attitude is everything!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 90
    boResult = [self insertDataAdvice:90 advice:@"Make people feel important!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 91
    boResult = [self insertDataAdvice:91 advice:@"Get good and skilled at what you do!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 92
    boResult = [self insertDataAdvice:92 advice:@"Make conversation with whoever you can and whenever you can. You can meet some interesting people!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 93
    boResult = [self insertDataAdvice:93 advice:@"Judge people based on your interactions with them, not on what other people say!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 94
    boResult = [self insertDataAdvice:94 advice:@"Don’t be afraid to start over!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 95
    boResult = [self insertDataAdvice:95 advice:@"Say please and thank you!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 96
    boResult = [self insertDataAdvice:96 advice:@"Hold the door for strangers!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 97
    boResult = [self insertDataAdvice:97 advice:@"Be the first to apologize and the first to forgive!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 98
    boResult = [self insertDataAdvice:98 advice:@"Have integrity in all that you do!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 99
    boResult = [self insertDataAdvice:99 advice:@"Let go of your ego!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 100
    boResult = [self insertDataAdvice:100 advice:@"Visualize your goals while you are in the shower!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 101
    boResult = [self insertDataAdvice:101 advice:@"Say NO to experiences that do not serve you!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 102
    boResult = [self insertDataAdvice:102 advice:@"Have grace with yourself and others!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 103
    boResult = [self insertDataAdvice:103 advice:@"Always believe in the impossible!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 104
    boResult = [self insertDataAdvice:104 advice:@"Practice safe driving!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 105
    boResult = [self insertDataAdvice:105 advice:@"Be kind to everyone you meet!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 106
    boResult = [self insertDataAdvice:106 advice:@"Save at least 10% of your income each month!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 107
    boResult = [self insertDataAdvice:107 advice:@"Spend less than you earn!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 108
    boResult = [self insertDataAdvice:108 advice:@"Maintain a monthly budget!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 109
    boResult = [self insertDataAdvice:109 advice:@"Speak lovingly to yourself!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 110
    boResult = [self insertDataAdvice:110 advice:@"Never stop learning!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 111
    boResult = [self insertDataAdvice:111 advice:@"Never stop growing!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 112
    boResult = [self insertDataAdvice:112 advice:@"Always believe in your dreams!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 113
    boResult = [self insertDataAdvice:113 advice:@"If you are tired, rest! But don’t you dare to quit!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 114
    boResult = [self insertDataAdvice:114 advice:@"Don’t be afraid to fail!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 115
    boResult = [self insertDataAdvice:115 advice:@"Always remain humble!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 116
    boResult = [self insertDataAdvice:116 advice:@"Stop settling for good enough! You deserve what’s best!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 117
    boResult = [self insertDataAdvice:117 advice:@"Never lose your hope! Unexpected blessings are coming your way!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 118
    boResult = [self insertDataAdvice:118 advice:@"Invest in yourself! It is the best investment you will ever make!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 119
    boResult = [self insertDataAdvice:119 advice:@"Ask questions everyday!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 120
    boResult = [self insertDataAdvice:120 advice:@"Read something inspirational right before bed and after waking. You could start with this app!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 121
    boResult = [self insertDataAdvice:121 advice:@"Say no distractions!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 122
    boResult = [self insertDataAdvice:122 advice:@"Improve your work every single day!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 123
    boResult = [self insertDataAdvice:123 advice:@"Be a hero to someone!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 124
    boResult = [self insertDataAdvice:124 advice:@"Be the most ethical person you know!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 125
    boResult = [self insertDataAdvice:125 advice:@"Create unforgettable moments with those you love!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 126
    boResult = [self insertDataAdvice:126 advice:@"Become stunningly polite!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 127
    boResult = [self insertDataAdvice:127 advice:@"Sell your TV!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 128
    boResult = [self insertDataAdvice:128 advice:@"Keep the promises you make to others and to yourself!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 129
    boResult = [self insertDataAdvice:129 advice:@"Give one of the greatest gifts of all: your attention!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 130
    boResult = [self insertDataAdvice:130 advice:@"Stop waiting for perfect condition! Act now!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 131
    boResult = [self insertDataAdvice:131 advice:@"Learn from the best!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 132
    boResult = [self insertDataAdvice:132 advice:@"Enjoy nature and the outdoors - there is a lifetime’s worth of wonder there!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 133
    boResult = [self insertDataAdvice:133 advice:@"Surround yourself with good company!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 134
    boResult = [self insertDataAdvice:134 advice:@"Stop comparing yourself to others! You are unique!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 135
    boResult = [self insertDataAdvice:135 advice:@"Practice silence daily!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 136
    boResult = [self insertDataAdvice:136 advice:@"Stress and worry less!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 137
    boResult = [self insertDataAdvice:137 advice:@"Use the stairs more often!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 138
    boResult = [self insertDataAdvice:138 advice:@"Enjoy the moment!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 139
    boResult = [self insertDataAdvice:139 advice:@"Not everyone will like you or have your best interests at heart, be okay with that but avoid these people if you can!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 140
    boResult = [self insertDataAdvice:140 advice:@"Don’t take rejection personally! It is a great learning experience!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 141
    boResult = [self insertDataAdvice:141 advice:@"When in doubt, take a deep breath!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 142
    boResult = [self insertDataAdvice:142 advice:@"Your limitations are just in your mind!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 143
    boResult = [self insertDataAdvice:143 advice:@"Keep your focus steadily on what you want!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 144
    boResult = [self insertDataAdvice:144 advice:@"Don’t take yourself too seriously! Take a moment and laugh at yourself. Life should be fun!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 145
    boResult = [self insertDataAdvice:145 advice:@"Never stay satisfied with your current accomplishments!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 146
    boResult = [self insertDataAdvice:146 advice:@"Your problems are opportunities for success!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 147
    boResult = [self insertDataAdvice:147 advice:@"Take every chance you get!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 148
    boResult = [self insertDataAdvice:148 advice:@"You are the only responsible for your life!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 149
    boResult = [self insertDataAdvice:149 advice:@"Stop doing what isn’t working and try new things to see what does work!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 150
    boResult = [self insertDataAdvice:150 advice:@"Quit a bad habit each week!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 151
    boResult = [self insertDataAdvice:151 advice:@"Never work for money, work for your passion!"];
    if(boResult == FALSE)
        return FALSE;
    
    return TRUE;
}

@end
