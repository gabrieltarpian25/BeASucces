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

// OPEN DATABASE
-(BOOL) openDatabase
{
    if(is_database_open == TRUE)
        return TRUE;
    
    const char *dbPath = [databasePath UTF8String];
    if(sqlite3_open(dbPath, &database) == SQLITE_OK)
    {
        NSLog(@"# Database opened");
        is_database_open = TRUE;
        return TRUE;
    }
    else
    {
        is_database_open = FALSE;
        NSLog(@"# Failed to open the database");
        return FALSE;
    }
}

// CLOSE DATABASE
-(void) closeDatabase
{
    if(is_database_open == TRUE)
    {
        sqlite3_close(database);
        is_database_open = FALSE;
        NSLog(@"# Database closed");
    }
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
        // open the database then execute the statement that creates it
        if([self openDatabase] == TRUE)
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
            
            [self closeDatabase];
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
    bool success = NO;
    
    NSString *insertSQL = [NSString stringWithFormat:@"insert into quotes (id, author, quote, category) values (\"%d\",\"%@\",\"%@\",\"%@\")", quoteId, author, quote,category];
    const char *insertStatement = [insertSQL UTF8String];
    sqlite3_prepare_v2(database, insertStatement, -1, &statement, NULL);
    int error_code = sqlite3_step(statement);
    if( error_code == SQLITE_DONE )
    {
        success = YES;
    }
    else NSLog(@"# ERROR: Error code is %d",error_code);
    
    sqlite3_reset(statement);
    
    if(success == NO)
        NSLog(@"# ERROR: Failed to insert quote %d into database",quoteId);
    
    return success;
}

-(BOOL) insertDataAdvice:(int)adviceId advice:(NSString *)advice
{
    bool success = NO;
    
    NSString *insertSQL = [NSString stringWithFormat:@"insert into advices (id, advice) values (\"%d\",\"%@\")", adviceId, advice];
    const char *insertStatement = [insertSQL UTF8String];
    sqlite3_prepare_v2(database, insertStatement, -1, &statement, NULL);
    
    if( sqlite3_step(statement) == SQLITE_DONE )
    {
        success = YES;
    }
    else
    {
        NSLog(@"# ERROR: Failed to insert the following advice id into database: %d ",adviceId);
        NSLog(@"Advice: %@",advice);
        NSLog(@"SQLite error ID is %d",sqlite3_step(statement));
    }
    
    sqlite3_reset(statement);
    
    return success;
}

-(NSString*) getQuoteByID:(int)quoteId
{
    // open the database then execute the statement
    if([self openDatabase])
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
                [self closeDatabase];
                return result;
            }
            else
            {
                NSLog(@"# ERROR: Failed to retrieve quote %d from the database", quoteId);
            }
        }
        
        [self closeDatabase];
    }
    
    return nil;
}

-(NSString*) getAdviceByID:(int)adviceId
{
    
    // open the database then execute the statement
    if( [self openDatabase] )
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
                [self closeDatabase];
                return result;
            }
            else
            {
                NSLog(@"# ERROR: Failed to retrieve advice %d from the database", adviceId);
            }
        }
        
        [self closeDatabase];
    }
    
    return nil;
}

-(NSString*) getAuthorByID:(int)quoteId
{
    // open the database then execute the statement
    if( [self openDatabase] )
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
                [self closeDatabase];
                return result;
            }
            else
            {
                NSLog(@"# ERROR: Failed to retrieve Author of quote %d from database", quoteId);
            }
        }
        
        [self closeDatabase];
    }
    
    return nil;
}

-(NSString*) getCategoryByID:(int)quoteId
{
    // open the database then execute the statement
    if( [self openDatabase] )
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
                [self closeDatabase];
                return result;
            }
            else
            {
                NSLog(@"# ERROR: failed to retrieve Category from database for quote %d",quoteId);
            }
        }
        
        [self closeDatabase];
    }
    
    return nil;
}

-(int) getNumberOfQuotes
{
    // open the database then execute the statement
    if( [self openDatabase] )
    {
        NSString *querySQL = [NSString stringWithFormat:@"select count(*) from quotes"];
        const char *queryStatement = [querySQL UTF8String];
        if( sqlite3_prepare_v2(database, queryStatement, -1, &statement, NULL) == SQLITE_OK)
        {
            // query was succesfully executed
            if( sqlite3_step(statement) == SQLITE_ROW)
            {
                int result = sqlite3_column_int(statement, 0);
                [self closeDatabase];
                return result;
            }
            else
            {
                NSLog(@"# ERROR: Failed to retrieve number of quotes from database");
            }
        }
        
        [self closeDatabase];
    }
    
    return -1;
}

-(int) getNumberOfAdvices
{
    // open the database then execute the statement
    if( [self openDatabase] )
    {
        NSString *querySQL = [NSString stringWithFormat:@"select count(*) from advices"];
        const char *queryStatement = [querySQL UTF8String];
        if( sqlite3_prepare_v2(database, queryStatement, -1, &statement, NULL) == SQLITE_OK)
        {
            // query was succesfully executed
            if( sqlite3_step(statement) == SQLITE_ROW)
            {
                int result = sqlite3_column_int(statement, 0);
                [self closeDatabase];
                return result;
            }
            else
            {
                NSLog(@"# ERROR: Failed to retrieve number of advices from database");
            }
        }
        
        [self closeDatabase];
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
                               quote:@"Twenty years from now you will be more disappointed by the things that you didn’t do than by the ones you did do. So throw off the bowlines. Sail away from the safe harbor. Catch the trade winds in your sails. Explore. Dream. Discover"
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
    
    // quote id = 51
    boResult = [self insertDataQuote:51
                              author:@"Steve Jobs"
                               quote:@"Being the richest man in the cemetery doesn’t matter to me. Going to bed at night saying we’ve done something wonderful...that’s what matters to me"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 52
    boResult = [self insertDataQuote:52
                              author:@"Steve Jobs"
                               quote:@"Your time is limited, so don’t waste it living someone else’s life. Don’t be trapped by dogma—which is living with the results of other people’s thinking. Don’t let the noise of others’ opinions drown out your own inner voice. And most important, have the courage to follow your heart and intuition. Everything else is secondary"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 53
    boResult = [self insertDataQuote:53
                              author:@"Steve Jobs"
                               quote:@"Things don’t have to change the world to be important"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 54
    boResult = [self insertDataQuote:54
                              author:@"Bill Gates"
                               quote:@"We all need people who will give us feedback. That's how we improve"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 55
    boResult = [self insertDataQuote:55
                              author:@"Bill Gates"
                               quote:@"It's fine to celebrate success but it is more important to heed the lessons of failure"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 56
    boResult = [self insertDataQuote:56
                              author:@"Bill Gates"
                               quote:@"Patience is a key element of success"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 57
    boResult = [self insertDataQuote:57
                              author:@"Bill Gates"
                               quote:@"Success is a lousy teacher. It seduces smart people into thinking they can’t lose"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 58
    boResult = [self insertDataQuote:58
                              author:@"Bill Gates"
                               quote:@"Don’t compare yourself with anyone in this world. If you do so, you are insulting yourself"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 59
    boResult = [self insertDataQuote:59
                              author:@"Bill Gates"
                               quote:@"I really had a lot of dreams when I was a kid, and I think a great deal of that grew out of the fact that I had a chance to read a lot"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 60
    boResult = [self insertDataQuote:60
                              author:@"Warren Buffett"
                               quote:@"It takes 20 years to build a reputation and five minutes to ruin it. If you think about that, you’ll do things differently"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 61
    boResult = [self insertDataQuote:61
                              author:@"Warren Buffett"
                               quote:@"Honesty is a very expensive gift. Don’t expect it from cheap people"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 62
    boResult = [self insertDataQuote:62
                              author:@"Warren Buffett"
                               quote:@"In the world of business, the people who are most successful are those who are doing what they love"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 63
    boResult = [self insertDataQuote:63
                              author:@"Warren Buffett"
                               quote:@"You’ve gotta keep control of your time, and you can’t unless you say no. You can’t let people set your agenda in life"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 64
    boResult = [self insertDataQuote:64
                              author:@"Warren Buffett"
                               quote:@"The most important investment you can make is in yourself"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 65
    boResult = [self insertDataQuote:65
                              author:@"T. Harv Eker"
                               quote:@"The number one reason most people don’t get what they want is that they don’t know what they want"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 66
    boResult = [self insertDataQuote:66
                              author:@"T. Harv Eker"
                               quote:@"If you want to change the fruits, you will first have to change the roots. If you want to change the visible, you must first change the invisible"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 67
    boResult = [self insertDataQuote:67
                              author:@"T. Harv Eker"
                               quote:@"Keep your eye on the goal, keep moving toward your target"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 68
    boResult = [self insertDataQuote:68
                              author:@"T. Harv Eker"
                               quote:@"Money will only make you more of what you already are"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 69
    boResult = [self insertDataQuote:69
                              author:@"T. Harv Eker"
                               quote:@"What you focus on expands"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 70
    boResult = [self insertDataQuote:70
                              author:@"T.Harv Eker"
                               quote:@"The purpose of our lives is to add value to the people of this generation and those that follow"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 71
    boResult = [self insertDataQuote:71
                              author:@"T.Harv Eker"
                               quote:@"Your life is not just about you. It’s also about contributing to others"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 72
    boResult = [self insertDataQuote:72
                              author:@"T.Harv Eker"
                               quote:@"If you are willing to do only what’s easy, life will be hard. But if you are willing to do what’s hard, life will be easy"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 73
    boResult = [self insertDataQuote:73
                              author:@"T.Harv Eker"
                               quote:@"If you want to make a permanent change, stop focusing on the size of your problems and start focusing on the size of you"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 74
    boResult = [self insertDataQuote:74
                              author:@"T.Harv Eker"
                               quote:@"If you are insecure, guess what? The rest of the world is too. Do not overestimate the competition and underestimate yourself. You are better than you think"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 75
    boResult = [self insertDataQuote:75
                              author:@"T.Harv Eker"
                               quote:@"Complaining is the absolute worst possible thing you could do for your health or your wealth. The worst! ... For the next seven days, I challenge you not to complain at all"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 76
    boResult = [self insertDataQuote:76
                              author:@"T.Harv Eker"
                               quote:@"Either you control money, or it will control you. To control money, you must manage it"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 77
    boResult = [self insertDataQuote:77
                              author:@"T.Harv Eker"
                               quote:@"The more you learn, the more you earn"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 78
    boResult = [self insertDataQuote:78
                              author:@"Napoleon Hill"
                               quote:@"Great achievement is usually born of great sacrifice, and is never the result of selfishness"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 79
    boResult = [self insertDataQuote:79
                              author:@"Napoleon Hill"
                               quote:@"If you cannot do great things, do small things in a great way"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 80
    boResult = [self insertDataQuote:80
                              author:@"Napoleon Hill"
                               quote:@"Your big opportunity may be right where you are now"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 81
    boResult = [self insertDataQuote:81
                              author:@"Napoleon Hill"
                               quote:@"Edison failed 10,000 times before he made the electric light. Do not be discouraged if you fail a few times"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 82
    boResult = [self insertDataQuote:82
                              author:@"Morihei Ueshiba"
                               quote:@"Failure is the key to success; each mistake teaches us something"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 83
    boResult = [self insertDataQuote:83
                              author:@"John C. Maxwell"
                               quote:@"The secret of your success is determined by your daily agenda"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 84
    boResult = [self insertDataQuote:84
                              author:@"Robin Sharma"
                               quote:@"Success is not a function of the size of your title but the richness of your contribution"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 85
    boResult = [self insertDataQuote:85
                              author:@"Wilma Mankiller"
                               quote:@"The secret of our success is that we never, never give up"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 86
    boResult = [self insertDataQuote:86
                              author:@"Zig Ziglar"
                               quote:@"Honesty and integrity are absolutely essential for success in life - all areas of life. The really good news is that anyone can develop both honesty and integrity"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 87
    boResult = [self insertDataQuote:87
                              author:@"Don Shula"
                               quote:@"Success is not forever and failure isn't fatal"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 88
    boResult = [self insertDataQuote:88
                              author:@"Dwayne Johnson"
                               quote:@"I'm always asked, 'What's the secret to success?' But there are no secrets. Be humble. Be hungry. And always be the hardest worker in the room"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 89
    boResult = [self insertDataQuote:89
                              author:@"Confucius"
                               quote:@"Success depends upon previous preparation, and without such preparation there is sure to be failure"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 90
    boResult = [self insertDataQuote:90
                              author:@"Julius Erving"
                               quote:@"The key to success is to keep growing in all areas of life - mental, emotional, spiritual, as well as physical"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 91
    boResult = [self insertDataQuote:91
                              author:@"Zig Ziglar"
                               quote:@"The foundation stones for a balanced success are honesty, character, integrity, faith, love and loyalty"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 92
    boResult = [self insertDataQuote:92
                              author:@"Michael Dell"
                               quote:@"You don't have to be a genius or a visionary or even a college graduate to be successful. You just need a framework and a dream"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 93
    boResult = [self insertDataQuote:93
                              author:@"Jon Bon Jovi"
                               quote:@"Success is falling nine times and getting up ten"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 94
    boResult = [self insertDataQuote:94
                              author:@"Ram Dass"
                               quote:@"You are loved just for being who you are, just for existing. You don't have to do anything to earn it. Your shortcomings, your lack of self-esteem, physical perfection, or social and economic success - none of that matters. No one can take this love away from you, and it will always be here"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 95
    boResult = [self insertDataQuote:95
                              author:@"Akshay Kumar"
                               quote:@"I'm not hungry for success. I am only hungry for good work, and that is how it is with most superstars. Every day I tell myself how fortunate I am to be where I am"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 96
    boResult = [self insertDataQuote:96
                              author:@"William Pollard"
                               quote:@"Learning and innovation go hand in hand. The arrogance of success is to think that what you did yesterday will be sufficient for tomorrow"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 97
    boResult = [self insertDataQuote:97
                              author:@"Denis Waitley"
                               quote:@"Success is almost totally dependent upon drive and persistence. The extra energy required to make another effort or try another approach is the secret of winning"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 98
    boResult = [self insertDataQuote:98
                              author:@"John D. Rockefeller"
                               quote:@"I do not think that there is any other quality so essential to success of any kind as the quality of perseverance. It overcomes almost everything, even nature"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 99
    boResult = [self insertDataQuote:99
                              author:@"Joel Osteen"
                               quote:@"God has already done everything He's going to do. The ball is now in your court. If you want success, if you want wisdom, if you want to be prosperous and healthy, you're going to have to do more than meditate and believe; you must boldly declare words of faith and victory over yourself and your family"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 100
    boResult = [self insertDataQuote:100
                              author:@"Norman Vincent Peale"
                               quote:@"Four things for success: work and pray, think and believe"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 101
    boResult = [self insertDataQuote:101
                              author:@"A. R. Rahman"
                               quote:@"Success comes to those who dedicate everything to their passion in life. To be successful, it is also very important to be humble and never let fame or money travel to your head"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 102
    boResult = [self insertDataQuote:102
                              author:@"Shiv Khera"
                               quote:@"Your positive action combined with positive thinking results in success"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 103
    boResult = [self insertDataQuote:103
                              author:@"Shah Rukh Khan"
                               quote:@"Success and failure are both part of life. Both are not permanent"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 104
    boResult = [self insertDataQuote:104
                              author:@"Selena Gomez"
                               quote:@"Success is nothing if you don't have the right people to share it with; you're just gonna end up lonely"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 105
    boResult = [self insertDataQuote:105
                              author:@"Oprah Winfrey"
                               quote:@"What material success does is provide you with the ability to concentrate on other things that really matter. And that is being able to make a difference, not only in your own life, but in other people's lives"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 106
    boResult = [self insertDataQuote:106
                              author:@"Christopher Morley"
                               quote:@"There is only one success - to be able to spend your life in your own way"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 107
    boResult = [self insertDataQuote:107
                              author:@"Margaret Thatcher"
                               quote:@"What is success? I think it is a mixture of having a flair for the thing that you are doing; knowing that it is not enough, that you have got to have hard work and a certain sense of purpose"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 108
    boResult = [self insertDataQuote:108
                              author:@"Malcolm Forbes"
                               quote:@"Failure is success if we learn from it"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 109
    boResult = [self insertDataQuote:109
                              author:@"Miguel de Cervantes"
                               quote:@"To be prepared is half the victory"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 110
    boResult = [self insertDataQuote:110
                              author:@"Joel Osteen"
                               quote:@"Prospering just doesn't have to do with money"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 111
    boResult = [self insertDataQuote:111
                              author:@"David LaChapelle"
                               quote:@"Success to me is being a good person, treating people well"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 112
    boResult = [self insertDataQuote:112
                              author:@"Vera Wang"
                               quote:@"Success isn't about the end result, it's about what you learn along the way"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 113
    boResult = [self insertDataQuote:113
                              author:@"Dada Vaswani"
                               quote:@"True success, true happiness lies in freedom and fulfillment"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 114
    boResult = [self insertDataQuote:114
                              author:@"Charlie White"
                               quote:@"The most important thing is being passionate about what you're doing and always give it your all. That is the key to success"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 115
    boResult = [self insertDataQuote:115
                              author:@"Maxwell Maltz"
                               quote:@"Remember you will not always win. Some days, the most resourceful individual will taste defeat. But there is, in this case, always tomorrow - after you have done your best to achieve success today"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 116
    boResult = [self insertDataQuote:116
                              author:@"William Osler"
                               quote:@"The very first step towards success in any occupation is to become interested in it"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 117
    boResult = [self insertDataQuote:117
                              author:@"Aesop"
                               quote:@"The level of our success is limited only by our imagination and no act of kindness, however small, is ever wasted"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 118
    boResult = [self insertDataQuote:118
                              author:@"Al Green"
                               quote:@"Teach success before teaching responsibility. Teach them to believe in themselves. Teach them to think, 'I'm not stupid'. No child wants to fail. Everyone wants to succeed"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 119
    boResult = [self insertDataQuote:119
                              author:@"Ravi Zacharias"
                               quote:@"Success is more difficult to handle than failure"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 120
    boResult = [self insertDataQuote:120
                              author:@"Zig Ziglar"
                               quote:@"Try to look at your weakness and convert it into your strength. That's success"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 121
    boResult = [self insertDataQuote:121
                              author:@"Myles Munroe"
                               quote:@"True leaders don't invest in buildings. Jesus never built a building. They invest in people. Why? Because success without a successor is failure. So your legacy should not be in buildings, programs, or projects; your legacy must be in people"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 122
    boResult = [self insertDataQuote:122
                              author:@"Bobby Davro"
                               quote:@"The measure of success is happiness and peace of mind"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 123
    boResult = [self insertDataQuote:123
                              author:@"William J. H. Boetcker"
                               quote:@"Your success depends mainly upon what you think of yourself and whether you believe in yourself"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 124
    boResult = [self insertDataQuote:124
                              author:@"Robert Louis Stevenson"
                               quote:@"That man is a success who has lived well, laughed often and loved much"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 125
    boResult = [self insertDataQuote:125
                              author:@"Arnold Schwarzenegger"
                               quote:@"Failure is not an option. Everyone has to succeed"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 126
    boResult = [self insertDataQuote:126
                              author:@"Joyce Brothers"
                               quote:@"Success is a state of mind. If you want success, start thinking of yourself as a success"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 127
    boResult = [self insertDataQuote:127
                              author:@"Joseph Addison"
                               quote:@"If you wish to succeed in life, make perseverance your bosom friend, experience your wise counselor, caution your elder brother, and hope your guardian genius"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id =128
    boResult = [self insertDataQuote:128
                              author:@"Johnny Carson"
                               quote:@"Never continue in a job you don't enjoy. If you're happy in what you're doing, you'll like yourself, you'll have inner peace. And if you have that, along with physical health, you will have had more success than you could possibly have imagined"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 129
    boResult = [self insertDataQuote:129
                              author:@"Dan Millman"
                               quote:@"Willpower is the key to success. Successful people strive no matter what they feel by applying their will to overcome apathy, doubt or fear"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 130
    boResult = [self insertDataQuote:130
                              author:@"Saint Augustine"
                               quote:@"Do you wish to rise? Begin by descending. You plan a tower that will pierce the clouds? Lay first the foundation of humility"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 131
    boResult = [self insertDataQuote:131
                              author:@"Arthur Ashe"
                               quote:@"One important key to success is self-confidence. An important key to self-confidence is preparation"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 132
    boResult = [self insertDataQuote: 132
                              author:@"Erin Cummings"
                               quote:@"At the end of the day, you are solely responsible for your success and your failure. And the sooner you realize that, you accept that, and integrate that into your work ethic, you will start being successful. As long as you blame others for the reason you aren't where you want to be, you will always be a failure"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 133
    boResult = [self insertDataQuote:133
                              author:@"Marvin Sapp"
                               quote:@"A friend of mine said something powerful at his grandfather's funeral. He said that the greatest lesson from his grandfather's life was that he died empty, because he accomplished everything he wanted, with no regrets. I think that, along with leaving a legacy, would be the greatest sign of success"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 134
    boResult = [self insertDataQuote:134
                              author:@"Wayne Huizenga"
                               quote:@"Some people dream of success, while other people get up every morning and make it happen"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 135
    boResult = [self insertDataQuote:135
                              author:@"Billie Jean King"
                               quote:@"A champion is afraid of losing. Everyone else is afraid of winning"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 136
    boResult = [self insertDataQuote:136
                              author:@"Dale Carnegie"
                               quote:@"The successful man will profit from his mistakes and try again in a different way"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 137
    boResult = [self insertDataQuote:137
                              author:@"John Wooden"
                               quote:@"Success is peace of mind which is a direct result of self-satisfaction in knowing you did your best to become the best you are capable of becoming"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 138
    boResult = [self insertDataQuote:138
                              author:@"Tennessee Williams"
                               quote:@"Success is blocked by concentrating on it and planning for it... Success is shy - it won't come out while you're watching"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 139
    boResult = [self insertDataQuote:139
                              author:@"Christopher Reeve"
                               quote:@"Success is finding satisfaction in giving a little more than you take"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 140
    boResult = [self insertDataQuote:140
                              author:@"Michelle Obama"
                               quote:@"We learned about gratitude and humility - that so many people had a hand in our success, from the teachers who inspired us to the janitors who kept our school clean... and we were taught to value everyone's contribution and treat everyone with respect"
                            category:@"Gratitude"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 141
    boResult = [self insertDataQuote:141
                              author:@"Denis Waitley"
                               quote:@"Success in life comes not from holding a good hand, but in playing a poor hand well"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 142
    boResult = [self insertDataQuote:142
                              author:@"Ray Kroc"
                               quote:@"If you work just for money, you'll never make it, but if you love what you're doing and you always put the customer first, success will be yours"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 143
    boResult = [self insertDataQuote:143
                              author:@"Zig Ziglar"
                               quote:@"I believe that being successful means having a balance of success stories across the many areas of your life. You can't truly be considered successful in your business life if your home life is in shambles"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 144
    boResult = [self insertDataQuote:144
                              author:@"Danny Thomas"
                               quote:@"All of us are born for a reason, but all of us don't discover why. Success in life has nothing to do with what you gain in life or accomplish for yourself. It's what you do for others"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 145
    boResult = [self insertDataQuote:145
                              author:@"William J. H. Boetcker"
                               quote:@"Never mind what others do; do better than yourself, beat your own record from day to day, and you are a success"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 146
    boResult = [self insertDataQuote:146
                              author:@"Adrien Brody"
                               quote:@"My dad told me, 'It takes fifteen years to be an overnight success', and it took me seventeen and a half years"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 147
    boResult = [self insertDataQuote:147
                              author:@"Sarah Hyland"
                               quote:@"I think success right now is not about how famous you are or how much you're getting paid, but it's more about if you're steadily working and you're happy with what you're doing"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 148
    boResult = [self insertDataQuote:148
                              author:@"Lindsey Wixson"
                               quote:@"Real success is not, like, materialistic. It's being where you want to be when you want to be; just living your life how you feel; having an ultimate goal and being able to accomplish it"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 149
    boResult = [self insertDataQuote:149
                              author:@"James Cameron"
                               quote:@"If you set your goals ridiculously high and it's a failure, you will fail above everyone else's success"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 150
    boResult = [self insertDataQuote:150
                              author:@"Etel Adnan"
                               quote:@"Do what your inner soul tells you to do, regardless of any money or success it will bring you"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 151
    boResult = [self insertDataQuote:151
                              author:@"Maria Bartiromo"
                               quote:@"I think that my biggest attribute to any success that I have had is hard work. There really is no substitute for working hard"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 152
    boResult = [self insertDataQuote:152
                              author:@"Kevin Spacey"
                               quote:@"It's always the big question in our lives if you have a lot of success. What do you do with it? Buy more houses, buy more cars, buy more stuff, be wealthy and distant and unengaged? Or do you take all that good fortune that has come towards you and spread the love, do something with it"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 153
    boResult = [self insertDataQuote:153
                              author:@"Henri Frederic Amiel"
                               quote:@"Everything you need for better future and success has already been written. And guess what? All you have to do is go to the library"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 154
    boResult = [self insertDataQuote:154
                              author:@"Zig Ziglar"
                               quote:@"Success is the maximum utilization of the ability that you have"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 155
    boResult = [self insertDataQuote:155
                              author:@"Johnny Carson"
                               quote:@"Talent alone won't make you a success. Neither will being in the right place at the right time, unless you are ready. The most important question is: 'Are your ready?"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 156
    boResult = [self insertDataQuote:156
                              author:@"Soichiro Honda"
                               quote:@"Success represents the 1% of your work which results from the 99% that is called failure"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 157
    boResult = [self insertDataQuote:157
                              author:@"Johnny Cash"
                               quote:@"Success is having to worry about every damn thing in the world, except money"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 158
    boResult = [self insertDataQuote:158
                              author:@"Jim Carrey"
                               quote:@"I think everybody should get rich and famous and do everything they ever dreamed of so they can see that it's not the answer"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 159
    boResult = [self insertDataQuote:159
                              author:@"P. T. Barnum"
                               quote:@"The foundation of success in life is good health: that is the substratum fortune; it is also the basis of happiness. A person cannot accumulate a fortune very well when he is sick"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 160
    boResult = [self insertDataQuote:160
                              author:@"Zig Ziglar"
                               quote:@"Success must never be measured by how much money you have"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 161
    boResult = [self insertDataQuote:161
                              author:@"Henry Samueli"
                               quote:@"Passion is what gives meaning to our lives. It's what allows us to achieve success beyond our wildest imagination. Try to find a career path that you have a passion for"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 162
    boResult = [self insertDataQuote:162
                              author:@"Jim Rohn"
                               quote:@"Success is nothing more than a few simple disciplines, practiced every day"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 163
    boResult = [self insertDataQuote:163
                              author:@"Jim Rohn"
                               quote:@"Formal education will make you a living; self-education will make you a fortune"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 164
    boResult = [self insertDataQuote:164
                              author:@"John Ruskin"
                               quote:@"When love and skill work together, expect a masterpiece"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 165
    boResult = [self insertDataQuote:165
                              author:@"Vince Lombardi"
                               quote:@"The difference between a successful person and others is not a lack of strength, not a lack of knowledge, but rather a lack of will"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 166
    boResult = [self insertDataQuote:166
                              author:@"William James"
                               quote:@"Success or failure depends more upon attitude than upon capacity successful men act as though they have accomplished or are enjoying something. Soon it becomes a reality.Act, look, feel successful, conduct yourself accordingly, and you will be amazed at the positive results"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 167
    boResult = [self insertDataQuote:167
                              author:@"W. Clement Stone"
                               quote:@"Success is achieved and maintained by those who try and keep trying"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 168
    boResult = [self insertDataQuote:168
                              author:@"Mike Ditka"
                               quote:@"Success isn't measured by money or power or social rank. Success is measured by your discipline and inner peace"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 169
    boResult = [self insertDataQuote:169
                              author:@"Jim Lovell"
                               quote:@"There are people who make things happen, there are people who watch things happen, and there are people who wonder what happened. To be successful, you need to be a person who makes things happen"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 170
    boResult = [self insertDataQuote:170
                              author:@"Vince Lombardi"
                               quote:@"The only place success comes before work is in the dictionary"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 171
    boResult = [self insertDataQuote:171
                              author:@"Mark Warner"
                               quote:@"My success was due to good luck, hard work, and support and advice from friends and mentors. But most importantly, it depended on me to keep trying after I had failed"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 172
    boResult = [self insertDataQuote:172
                              author:@"Bo Bennett"
                               quote:@"When it comes to success, there are no shortcuts"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 173
    boResult = [self insertDataQuote:173
                              author:@"Paul Sweeney"
                               quote:@"True success is overcoming the fear of being unsuccessful"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 174
    boResult = [self insertDataQuote:174
                              author:@"Denis Waitley"
                               quote:@"Forget about the consequences of failure. Failure is only a temporary change in direction to set you straight for your next success"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 175
    boResult = [self insertDataQuote:175
                              author:@"Tony Robbins"
                               quote:@"Success comes from taking the initiative and following up... persisting... eloquently expressing the depth of your love. What simple action could you take today to produce a new momentum toward success in your life?"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 176
    boResult = [self insertDataQuote:176
                              author:@"Napoleon Hill"
                               quote:@"Most great people have attained their greatest success just one step beyond their greatest failure"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 177
    boResult = [self insertDataQuote:177
                              author:@"Cullen Hightower"
                               quote:@"A true measure of your worth includes all the benefits others have gained from your success"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 178
    boResult = [self insertDataQuote:178
                              author:@"Samuel Smiles"
                               quote:@"We learn wisdom from failure much more than from success. We often discover what will do, by finding out what will not do; and probably he who never made a mistake never made a discovery"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 179
    boResult = [self insertDataQuote:179
                              author:@"Tony Robbins"
                               quote:@"My definition of success is to live your life in a way that causes you to feel a ton of pleasure and very little pain - and because of your lifestyle, have the people around you feel a lot more pleasure than they do pain"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 180
    boResult = [self insertDataQuote:180
                              author:@"Bob Riley"
                               quote:@"No skill shapes a child's future success in school or in life more than the ability to read"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 181
    boResult = [self insertDataQuote:181
                              author:@"Oprah Winfrey"
                               quote:@"You know you are on the road to success if you would do your job, and not be paid for it"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 182
    boResult = [self insertDataQuote:182
                              author:@"Danny Thomas"
                               quote:@"Success has nothing to do with what you gain in life or accomplish for yourself. It's what you do for others"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 183
    boResult = [self insertDataQuote:183
                              author:@"W. Clement Stone"
                               quote:@"Like success, failure is many things to many people. With Positive Mental Attitude, failure is a learning experience, a rung on the ladder, a plateau at which to get your thoughts in order and prepare to try again"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 184
    boResult = [self insertDataQuote:184
                              author:@"Tony Levin"
                               quote:@"People should decide what success means for them, and not be distracted by accepting others' definitions of success"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 185
    boResult = [self insertDataQuote:185
                              author:@"Denis Waitley"
                               quote:@"The winner's edge is not in a gifted birth, a high IQ, or in talent. The winner's edge is all in the attitude, not aptitude. Attitude is the criterion for success"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 186
    boResult = [self insertDataQuote:186
                              author:@"Arianna Huffington"
                               quote:@"We need to accept that we won't always make the right decisions, that we'll screw up royally sometimes - understanding that failure is not the opposite of success, it's part of success"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 187
    boResult = [self insertDataQuote:187
                              author:@"Rickey Henderson"
                               quote:@"Once you can accept failure, you can have fun and success"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 188
    boResult = [self insertDataQuote:188
                              author:@"Whoopi Goldberg"
                               quote:@"We're born with success. It is only others who point out our failures, and what they attribute to us as failure"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 189
    boResult = [self insertDataQuote:189
                              author:@"Celine Dion"
                               quote:@"The hardest thing to find in life is balance - especially the more success you have, the more you look to the other side of the gate. What do I need to stay grounded, in touch, in love, connected, emotionally balanced? Look within yourself"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 190
    boResult = [self insertDataQuote:190
                              author:@"T. D. Jakes"
                               quote:@"I raised five children. They all have different personalities. All of them have different issues, different levels of success. That was a learning experience for me"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 191
    boResult = [self insertDataQuote:191
                              author:@"Jessye Norman"
                               quote:@"One needs more than ambition and talent to make a success of anything, really. There must be love and a vocation"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 192
    boResult = [self insertDataQuote:192
                              author:@"Simon Cowell"
                               quote:@"The secret of my success is that I make other people money. And, never ever, ever, ever be ashamed about trying to earn as much as possible for yourself, if the person you're working with is also making money. That's life"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 193
    boResult = [self insertDataQuote:193
                              author:@"Maharishi Mahesh Yogi"
                               quote:@"Problems or successes, they all are the results of our own actions. Karma. The philosophy of action is that no one else is the giver of peace or happiness. One's own karma, one's own actions are responsible to come to bring either happiness or success or whatever"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 194
    boResult = [self insertDataQuote:194
                              author:@"Tyler Perry"
                               quote:@"My biggest success is getting over the things that have tried to destroy and take me out of this life. Those are my biggest successes. It has nothing to do with work"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 195
    boResult = [self insertDataQuote:195
                              author:@"Sylvester Stallone"
                               quote:@"I believe any success in life is made by going into an area with a blind, furious optimism"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 196
    boResult = [self insertDataQuote:196
                              author:@"Andrew Lloyd Webber"
                               quote:@"What strikes me is that there's a very fine line between success and failure. Just one ingredient can make the difference"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 197
    boResult = [self insertDataQuote:197
                              author:@"Jeremy Luke"
                               quote:@"The definition of success to me is not necessarily a price tag, not fame, but having a good life, and being able to say I did the right thing at the end of the day"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 198
    boResult = [self insertDataQuote:198
                              author:@"Les Brown"
                               quote:@"We were all born with a certain degree of power. The key to success is discovering this innate power and using it daily to deal with whatever challenges come our way"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 199
    boResult = [self insertDataQuote:199
                              author:@"Jessica Savitch"
                               quote:@"I worked half my life to be an overnight success, and still it took me by surprise"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 200
    boResult = [self insertDataQuote:200
                              author:@"Bob Dylan"
                               quote:@"What's money? A man is a success if he gets up in the morning and goes to bed at night and in between does what he wants to do"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 201
    boResult = [self insertDataQuote:201
                              author:@"Jean Giraudoux"
                               quote:@"The secret of success is sincerity"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 202
    boResult = [self insertDataQuote:202
                              author:@"Bessie Anderson Stanley"
                               quote:@"To know even one life has breathed easier because you have lived. This is to have succeeded"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 203
    boResult = [self insertDataQuote:203
                              author:@"Wayne Dyer"
                               quote:@"Successful people make money. It's not that people who make money become successful, but that successful people attract money. They bring success to what they do"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 204
    boResult = [self insertDataQuote:204
                              author:@"Kathy Ireland"
                               quote:@"If we get our self-esteem from superficial places, from our popularity, appearance, business success, financial situation, health, any of these, we will be disappointed, because no one can guarantee that we'll have them tomorrow"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 205
    boResult = [self insertDataQuote:205
                              author:@"Nolan Ryan"
                               quote:@"Enjoying success requires the ability to adapt. Only by being open to change will you have a true opportunity to get the most from your talent"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 206
    boResult = [self insertDataQuote:206
                              author:@"Thomas Wolfe"
                               quote:@"You have reached the pinnacle of success as soon as you become uninterested in money, compliments, or publicity."
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 207
    boResult = [self insertDataQuote:207
                              author:@"Rani Mukerji"
                               quote:@"I'm not bothered about what people say behind my back. I don't need to know about it. I believe in living my life and doing my work. God will give you success. And even if He doesn't, there's a lesson to be learnt"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 208
    boResult = [self insertDataQuote:208
                              author:@"Jim Rohn"
                               quote:@"Success is steady progress toward one's personal goals"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 209
    boResult = [self insertDataQuote:209
                              author:@"Anthony J. D'Angelo"
                               quote:@"In order to succeed you must fail, so that you know what not to do the next time"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 210
    boResult = [self insertDataQuote:210
                              author:@"Thomas J. Watson"
                               quote:@"To be successful, you have to have your heart in your business and your business in your heart"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 211
    boResult = [self insertDataQuote:211
                              author:@"Brenda Song"
                               quote:@"To this day, just always treat people the way you want to be treated. Whether it's family or friends or co-workers, I think it's the most important thing. Whether you have success or don't have it, whether you're a good person is all that matters"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 212
    boResult = [self insertDataQuote:212
                              author:@"Elbert Hubbard"
                               quote:@"A little more persistence, a little more effort, and what seemed hopeless failure may turn to glorious success"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 213
    boResult = [self insertDataQuote:213
                              author:@"Brendon Burchard"
                               quote:@"If you create incredible value and information for others that can change their lives - and you always stay focused on that service - the financial success will follow"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 214
    boResult = [self insertDataQuote:214
                              author:@"Brendon Burchard"
                               quote:@"Challenge is the pathway to engagement and progress in our lives. But not all challenges are created equal. Some challenges make us feel alive, engaged, connected, and fulfilled. Others simply overwhelm us. Knowing the difference as you set bigger and bolder challenges for yourself is critical to your sanity, success, and satisfaction"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 215
    boResult = [self insertDataQuote:215
                              author:@"Harvey Mackay"
                               quote:@"It doesn't matter whether you are pursuing success in business, sports, the arts, or life in general: The bridge between wishing and accomplishing is discipline"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 216
    boResult = [self insertDataQuote:216
                              author:@"Jack Canfield"
                               quote:@"The longer you hang in there, the greater the chance that something will happen in your favor. No matter how hard it seems, the longer you persist, the more likely your success"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 217
    boResult = [self insertDataQuote:217
                              author:@"Jack Canfield"
                               quote:@"I used to define success as being able to produce any result you wanted, whether it was a relationship, weight-loss, being a millionaire, impacting the culture, changing society, whatever it might be - it might be homelessness, whatever - and lately, I've redefined success as 'fulfilling your soul's purpose'"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 218
    boResult = [self insertDataQuote:218
                              author:@"Jack Canfield"
                               quote:@"In working with top leaders and thought philosophers of our time, I will tell you that among their secrets of success is a regular practice of acknowledging and appreciating what they have"
                            category:@"Gratitude"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 219
    boResult = [self insertDataQuote:219
                              author:@"B. C. Forbes"
                               quote:@"The man who has done his level best... is a success, even though the world may write him down a failure"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 220
    boResult = [self insertDataQuote:220
                              author:@"Paul J. Meyer"
                               quote:@"Success is the progressive realization of predetermined, worthwhile, personal goals"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 221
    boResult = [self insertDataQuote:221
                              author:@"Charlotte Whitton"
                               quote:@"It's how you deal with failure that determines how you achieve success"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 222
    boResult = [self insertDataQuote:222
                              author:@"Dada Vaswani"
                               quote:@"Whenever you have taken up work in hand, you must see it to the finish. That is the ultimate secret of success. Never, never, never give up"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 223
    boResult = [self insertDataQuote:223
                              author:@"Malcolm X"
                               quote:@"In all our deeds, the proper value and respect for time determines success or failure"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 224
    boResult = [self insertDataQuote:224
                              author:@"Denis Waitley"
                               quote:@"Personal satisfaction is the most important ingredient of success"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 225
    boResult = [self insertDataQuote:225
                              author:@"Napoleon Hill"
                               quote:@"Success in its highest and noblest form calls for peace of mind and enjoyment and happiness which come only to the man who has found the work that he likes best"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 226
    boResult = [self insertDataQuote:226
                              author:@"Charles J. Givens"
                               quote:@"Achieve success in any area of life by identifying the optimum strategies and repeating them until they become habits"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 227
    boResult = [self insertDataQuote:227
                              author:@"Sumner Redstone"
                               quote:@"Success is not built on success. It's built on failure. It's built on frustration. Sometimes its built on catastrophe"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 228
    boResult = [self insertDataQuote:228
                              author:@"Orison Swett Marden"
                               quote:@"The greatest thing a man can do in this world is to make the most possible out of the stuff that has been given him. This is success, and there is no other"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 229
    boResult = [self insertDataQuote:229
                              author:@"Calvin Coolidge"
                               quote:@"If I had permitted my failures, or what seemed to me at the time a lack of success, to discourage me I cannot see any way in which I would ever have made progress"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 230
    boResult = [self insertDataQuote:230
                              author:@"Malcolm Forbes"
                               quote:@"Success follows doing what you want to do. There is no other way to be successful"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 231
    boResult = [self insertDataQuote:231
                              author:@"Warren Beatty"
                               quote:@"You've achieved success in your field when you don't know whether what you're doing is work or play"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 232
    boResult = [self insertDataQuote:232
                              author:@"Michael Flatley"
                               quote:@"Whenever I hear, 'It can't be done,' I know I'm close to success"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 233
    boResult = [self insertDataQuote:233
                              author:@"Brendan Fraser"
                               quote:@"I'm starting to judge success by the time I have for myself, the time I spend with family and friends. My priorities aren't amending; they're shifting"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 234
    boResult = [self insertDataQuote:234
                              author:@"Robert Collier"
                               quote:@"Your chances of success in any undertaking can always be measured by your belief in yourself"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 235
    boResult = [self insertDataQuote:235
                              author:@"Kathy Ireland"
                               quote:@"I believe there are three keys to success. For me it is keeping my priorities in order: It's my faith and my family, and then the business"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 236
    boResult = [self insertDataQuote:236
                              author:@"Jonathan Sacks"
                               quote:@"Follow your passion. Nothing - not wealth, success, accolades or fame - is worth spending a lifetime doing things you don't enjoy"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 237
    boResult = [self insertDataQuote:237
                              author:@"Ben Carson"
                               quote:@"With everything that is complex, we learn. If you don't learn, then it's an utter and abject failure. If you do learn, and you're able to apply that to the next situation, then you take away a measure of success"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 238
    boResult = [self insertDataQuote:238
                              author:@"Jack Canfield"
                               quote:@"Greater self-esteem produces greater success, and greater success produces more high self-esteem, so it keeps on spiraling up"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 239
    boResult = [self insertDataQuote:239
                              author:@"Ana Ivanovic"
                               quote:@"Fame and success and titles stay with you, but they wear out eventually. In the end, all that you are left with is your character"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 240
    boResult = [self insertDataQuote:240
                              author:@"Jay Samit"
                               quote:@"There is a huge difference between failing and failure. Failing is trying something that you learn doesn't work. Failure is throwing in the towel and giving up. True success comes from failing repeatedly and as quickly as possible, before your cash or your willpower runs out"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 241
    boResult = [self insertDataQuote:241
                              author:@"James Dyson"
                               quote:@"Enjoy failure and learn from it. You can never learn from success"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 242
    boResult = [self insertDataQuote:242
                              author:@"Irving Berlin"
                               quote:@"The toughest thing about success is that you've got to keep on being a success"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 243
    boResult = [self insertDataQuote:243
                              author:@"Louisa May Alcott"
                               quote:@"Have regular hours for work and play; make each day both useful and pleasant, and prove that you understand the worth of time by employing it well. Then youth will be delightful, old age will bring few regrets, and life will become a beautiful success"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 244
    boResult = [self insertDataQuote:244
                              author:@"Marilyn vos Savant"
                               quote:@"Success is achieved by developing our strengths, not by eliminating our weaknesses"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 245
    boResult = [self insertDataQuote:245
                              author:@"James Allen"
                               quote:@"The more tranquil a man becomes, the greater is his success, his influence, his power for good. Calmness of mind is one of the beautiful jewels of wisdom"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 246
    boResult = [self insertDataQuote:246
                              author:@"Michael Korda"
                               quote:@"Success has always been easy to measure. It is the distance between one's origins and one's final achievement"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 247
    boResult = [self insertDataQuote:247
                              author:@"David Icke"
                               quote:@"A friend at school was always being laughed at because his father emptied dustbins for a living. But those who laughed worshipped famous footballers. This is an example of our topsy-turvy view of 'success.' Who would we miss most if they did not work for a month, the footballer or the garbage collector"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 248
    boResult = [self insertDataQuote:248
                              author:@"Deepak Chopra"
                               quote:@"In a person's career, well, if you're process-oriented and not totally outcome-oriented, then you're more likely to be success. I often say 'pursue excellence, ignore success.' Success is a by-product of excellence"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 249
    boResult = [self insertDataQuote:249
                              author:@"Marlee Matlin"
                               quote:@"You can do anything if you set your mind to it. Look out for kids, help them dream and be inspired. We teach calculus in schools, but I believe the most important formula is courage plus dreams equals success"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 250
    boResult = [self insertDataQuote:250
                              author:@"Dale Carnegie"
                               quote:@"You never achieve success unless you like what you are doing"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 251
    boResult = [self insertDataQuote:251
                              author:@"Charles J. Givens"
                               quote:@"Success requires first expending ten units of effort to produce one unit of results. Your momentum will then produce ten units of results with each unit of effort"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 252
    boResult = [self insertDataQuote:252
                              author:@"Bo Bennett"
                               quote:@"Success is not in what you have, but who you are"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 253
    boResult = [self insertDataQuote:253
                              author:@"Alan Greenspan"
                               quote:@"I have found no greater satisfaction than achieving success through honest dealing and strict adherence to the view that, for you to gain, those you deal with should gain as well"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 254
    boResult = [self insertDataQuote:254
                              author:@"Nelson Boswell"
                               quote:@"The first and most important step toward success is the feeling that we can succeed"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 255
    boResult = [self insertDataQuote:255
                              author:@"Jane Rule"
                               quote:@"My private measure of success is daily. If this were to be the last day of my life would I be content with it? To live in a harmonious balance of commitments and pleasures is what I strive for"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 256
    boResult = [self insertDataQuote:256
                              author:@"Herschel Walker"
                               quote:@"I was a little different. I still say I'm a little different, because success to me is not having the most money, or having the biggest car or the biggest house"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 257
    boResult = [self insertDataQuote:257
                              author:@"Omar Epps"
                               quote:@"I believe success is preparation, because opportunity is going to knock on your door sooner or later but are you prepared to answer that"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 258
    boResult = [self insertDataQuote:258
                              author:@"Calvin Klein"
                               quote:@"I don't dwell on success. Maybe that's one reason I'm successful"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 259
    boResult = [self insertDataQuote:259
                              author:@"Zig Ziglar"
                               quote:@"You do not pay the price of success, you enjoy the price of success"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 260
    boResult = [self insertDataQuote:260
                              author:@"John Osborne"
                               quote:@"There's no such thing as failure - just waiting for success"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 261
    boResult = [self insertDataQuote:261
                              author:@"Bonnie Blair"
                               quote:@"I never could have achieved the success that I have without setting physical activity and health goals"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 262
    boResult = [self insertDataQuote:262
                              author:@"Allan Houston"
                               quote:@"Success isn't always going to be a huge contract; success is going to be if you just live out your purpose in life"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 263
    boResult = [self insertDataQuote:263
                              author:@"Whoopi Goldberg"
                               quote:@"I think the idea that you know who your inner self is on a daily basis, because... you know. What's good for you 25 years ago may not be good for you now. So, to keep in touch with that, I think that's the first ingredient for success. Because if you're a successful human being, everything else is gravy, I think"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 264
    boResult = [self insertDataQuote:264
                              author:@"Ryan Tedder"
                               quote:@"When you're around enormously successful people you realise their success isn't an accident - it's about work"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 265
    boResult = [self insertDataQuote:265
                              author:@"Harvey Mackay"
                               quote:@"Humility is becoming a lost art, but it's not difficult to practice. It means that you realize that others have been involved in your success"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 266
    boResult = [self insertDataQuote:266
                              author:@"James Avery"
                               quote:@"Monetary success is not success. Career success is not success. Life, someone that loves you, giving to others, doing something that makes you feel complete and full. That is success. And it isn't dependent on anyone else"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 267
    boResult = [self insertDataQuote:267
                              author:@"Seth MacFarlane"
                               quote:@"Believe it or not, I have about the same success rate as anyone else. Sometimes you hit, sometimes you miss"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 268
    boResult = [self insertDataQuote:268
                              author:@"Satya Nadella"
                               quote:@"Be passionate and bold. Always keep learning. You stop doing useful things if you don't learn. So the last part to me is the key, especially if you have had some initial success. It becomes even more critical that you have the learning 'bit' always switched on"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 269
    boResult = [self insertDataQuote:269
                              author:@"Helmut Jahn"
                               quote:@"Success on one project does not necessarily mean success in the next project. You've got to be prepared in everything you do"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 270
    boResult = [self insertDataQuote:270
                              author:@"Walter Scott"
                               quote:@"Success - keeping your mind awake and your desire asleep"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 271
    boResult = [self insertDataQuote:271
                              author:@"George Edward Woodberry"
                               quote:@"Defeat is not the worst of failures. Not to have tried is the true failure"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 272
    boResult = [self insertDataQuote:272
                              author:@"Gustave Flaubert"
                               quote:@"The most glorious moments in your life are not the so-called days of success, but rather those days when out of dejection and despair you feel rise in you a challenge to life, and the promise of future accomplishments"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 273
    boResult = [self insertDataQuote:273
                              author:@"Booker T. Washington"
                               quote:@"I have learned that success is to be measured not so much by the position that one has reached in life as by the obstacles which he has had to overcome while trying to succeed"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 274
    boResult = [self insertDataQuote:274
                              author:@"Anna Pavlova"
                               quote:@"Success depends in a very large measure upon individual initiative and exertion, and cannot be achieved except by a dint of hard work"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 275
    boResult = [self insertDataQuote:275
                              author:@"Sloan Wilson"
                               quote:@"Success in almost any field depends more on energy and drive than it does on intelligence. This explains why we have so many stupid leaders"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 276
    boResult = [self insertDataQuote:276
                              author:@"Kevin Bacon"
                               quote:@"Part of being a man is learning to take responsibility for your successes and for your failures. You can't go blaming others or being jealous. Seeing somebody else's success as your failure is a cancerous way to live"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 277
    boResult = [self insertDataQuote:277
                              author:@"Henry Ward Beecher"
                               quote:@"In this world it is not what we take up, but what we give up, that makes us rich"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 278
    boResult = [self insertDataQuote:278
                              author:@"Elbert Hubbard"
                               quote:@"He has achieved success who has worked well, laughed often, and loved much"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 279
    boResult = [self insertDataQuote:279
                              author:@"Christie Hefner"
                               quote:@"I don't think about financial success as the measurement of my success"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 280
    boResult = [self insertDataQuote:280
                              author:@"Sydney Madwed"
                               quote:@"If you want to be truly successful invest in yourself to get the knowledge you need to find your unique factor. When you find it and focus on it and persevere your success will blossom"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 281
    boResult = [self insertDataQuote:281
                              author:@"Robin Sharma"
                               quote:@"Why measure your success by the suggestions of society when you can become a success on your own terms?"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 282
    boResult = [self insertDataQuote:282
                              author:@"Robin Sharma"
                               quote:@"It takes massive work, hard focus and ridiculous amounts of grit + practice to get lucky"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 283
    boResult = [self insertDataQuote:283
                              author:@"Robin Sharma"
                               quote:@"Every pro was once an amateur. Every master was once a beginner. Why wait for the ideal time when you know you can start today?"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 284
    boResult = [self insertDataQuote:284
                              author:@"Robin Sharma"
                               quote:@"No one will believe how good you are until you believe how good you are"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 285
    boResult = [self insertDataQuote:285
                              author:@"Brian Tracy"
                               quote:@"To make changes in your future, make changes today"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 286
    boResult = [self insertDataQuote:286
                              author:@"Brian Tracy"
                               quote:@"It is not what you say, or wish, or hope or intend, it is only what you do that counts"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 287
    boResult = [self insertDataQuote:287
                              author:@"Oprah Winfrey"
                               quote:@"Everything you want is out there waiting for you to ask"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 288
    boResult = [self insertDataQuote:288
                              author:@"Jack Canfield"
                               quote:@"In the end, we only regret the chances we didn't take"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 289
    boResult = [self insertDataQuote:289
                              author:@"Oprah Winfrey"
                               quote:@"he big secret in life is that there is no secret. Whatever is your goal, you can get there if you are willing to work"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 290
    boResult = [self insertDataQuote:290
                              author:@"Arthur Rubinstein"
                               quote:@"I have found that if you love life, life will love you back"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 291
    boResult = [self insertDataQuote:291
                              author:@"Milton Berle"
                               quote:@"If opportunity doesn't knock, build a door"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 292
    boResult = [self insertDataQuote:292
                              author:@"Jack Canfield"
                               quote:@"Gratitude is the single most important ingredient to live a successful and fulfilled life"
                            category:@"Gratitude"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 293
    boResult = [self insertDataQuote:293
                              author:@"Mark Twain"
                               quote:@"The secret of getting ahead is getting started"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 294
    boResult = [self insertDataQuote:294
                              author:@"Norman Vincent Peale"
                               quote:@"It's always to soon to quit"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 295
    boResult = [self insertDataQuote:295
                              author:@"Ancient Chinese Proverb"
                               quote:@"A journey of 1.000 miles begins with one step"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 296
    boResult = [self insertDataQuote:296
                              author:@"Jack Canfield"
                               quote:@"Give up blaming, complaining and excuse making, and keep taking action in the direction of your goals, however mundane or lofty they may be"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 297
    boResult = [self insertDataQuote:297
                              author:@"William Gladstone"
                               quote:@"No man ever became great or good except through many and great mistakes"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 298
    boResult = [self insertDataQuote:298
                              author:@"Charles Kettering"
                               quote:@"Believe and act as if it were impossible to fail"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 299
    boResult = [self insertDataQuote:299
                              author:@"Jack Canfield"
                               quote:@"Successful people maintain a positive focus in life no matter what is going on around them"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 300
    boResult = [self insertDataQuote:300
                              author:@"Jack Canfield"
                               quote:@"Let go of doubts and start believing that you can do whatever it is you set out to do"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 301
    boResult = [self insertDataQuote:301
                              author:@"Arnold Schwarzenegger"
                               quote:@"Create a vision of who you want to be, and then live in that picture as if it were already true"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 302
    boResult = [self insertDataQuote:302
                              author:@"Jack Canfield"
                               quote:@"When you think you can't, revisit a previous triumph"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 303
    boResult = [self insertDataQuote:303
                              author:@"Jane Fonda"
                               quote:@"It's never too late - never too late to start over, never too late to be happy"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 304
    boResult = [self insertDataQuote:304
                              author:@"Michelangelo"
                               quote:@"The greater danger for most of us is not that our aim is too high and we miss it, but that it is too low and we reach it"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 305
    boResult = [self insertDataQuote:305
                              author:@"Brian Tracy"
                               quote:@"Decide on your major definite purpose in life and then organize all of your activities around it"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 306
    boResult = [self insertDataQuote:306
                              author:@"Wayne Dyer"
                               quote:@"All blame is a waste of time. No matter how much fault you find with another, and regardless of how much you blame him, it will not change you"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 307
    boResult = [self insertDataQuote:307
                              author:@"Booker T. Washington"
                               quote:@"If you want to lift yourself up, lift up someone else"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 308
    boResult = [self insertDataQuote:308
                              author:@"Brian Tracy"
                               quote:@"It doesn't matter where you are coming from. All that matters is where you are going"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 309
    boResult = [self insertDataQuote:309
                              author:@"Unknown"
                               quote:@"Go where you are celebrated - not tolerated. If they can't see the real value of you, it's time for a new start"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 310
    boResult = [self insertDataQuote:310
                              author:@"Brian Tracy"
                               quote:@"Start every morning by saying 'I believe something wonderful is going to happen to me today'. Repeat it over and over"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 311
    boResult = [self insertDataQuote:311
                              author:@"Albert Einstein"
                               quote:@"We cannot solve our problems with the same thinking we used when we created them"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 312
    boResult = [self insertDataQuote:312
                              author:@"Albert Einstein"
                               quote:@"Education is what remains after one has forgotten what one has learned in school"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 313
    boResult = [self insertDataQuote:313
                              author:@"Albert Einstein"
                               quote:@"A person who never made a mistake never tried anything new"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 314
    boResult = [self insertDataQuote:314
                              author:@"Albert Einstein"
                               quote:@"I have no special talent. I am only passionately curious"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 315
    boResult = [self insertDataQuote:315
                              author:@"Mahatma Gandhi"
                               quote:@"It is health that is real wealth and not pieces of gold and silver"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 316
    boResult = [self insertDataQuote:316
                              author:@"Ellen Degeneres"
                               quote:@"When you take risks you learn that there will be times when you succeed and there will be times when you fail, and both are equally important"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 317
    boResult = [self insertDataQuote:317
                              author:@"Brian Tracy"
                               quote:@"The only thing you can never have too much of is love"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 318
    boResult = [self insertDataQuote:318
                              author:@"Brian Tracy"
                               quote:@"Continuous learning is the minimum requirement for success in your field. Learn something new every day"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 319
    boResult = [self insertDataQuote:319
                              author:@"Michael Phelps"
                               quote:@"There will be obstacles. There will be doubters. There will be mistakes. But with hard work, there are no limits"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 320
    boResult = [self insertDataQuote:320
                              author:@"Eleanor Roosevelt"
                               quote:@"Do one thing every day that scares you"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 321
    boResult = [self insertDataQuote:321
                              author:@"Jim Rohn"
                               quote:@"Motivation is what gets you started. Habit is what keeps you going"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 322
    boResult = [self insertDataQuote:322
                              author:@"Jim Rohn"
                               quote:@"Successful people have libraries, the rest have big screen TVs"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 323
    boResult = [self insertDataQuote:323
                              author:@"Brian Tracy"
                               quote:@"You are far smarter than you can ever imagine. Your mind is a muscle, it only develops with use"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 324
    boResult = [self insertDataQuote:324
                              author:@"Tom Hopkins"
                               quote:@"Begin by always expecting good things to happen"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 325
    boResult = [self insertDataQuote:325
                              author:@"Brian Tracy"
                               quote:@"Money is hard to earn and easy to lose. Guard yours with care"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 326
    boResult = [self insertDataQuote:326
                              author:@"Og Mandino"
                               quote:@"Always do your best. What you plant now, will harvest later"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 327
    boResult = [self insertDataQuote:327
                              author:@"Brian Tracy"
                               quote:@"Stop talking about the problem and start thinking about the solution"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 328
    boResult = [self insertDataQuote:328
                              author:@"Jim Rohn"
                               quote:@"Either you run the day, or the day runs you"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 329
    boResult = [self insertDataQuote:329
                              author:@"Brian Tracy"
                               quote:@"If you do what you love and commit to being the best in your field, you will find success"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 330
    boResult = [self insertDataQuote:330
                              author:@"C.S. Lewis"
                               quote:@"You are never to old to set another goal or to dream a new dream"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 331
    boResult = [self insertDataQuote:331
                              author:@"Maya Angelou"
                               quote:@"We may encounter many defeats but we must not be defeated"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 332
    boResult = [self insertDataQuote:332
                              author:@"Nelson Mandela"
                               quote:@"It always seems impossible until it's done"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 333
    boResult = [self insertDataQuote:333
                              author:@"Brian Tracy"
                               quote:@"The biggest mistake you can make is to think you work for anyone else other than yourself"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 334
    boResult = [self insertDataQuote:334
                              author:@"Brian Tracy"
                               quote:@"There are no extra human beings; you are on this earth to do something special with your life"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 335
    boResult = [self insertDataQuote:335
                              author:@"Unknown"
                               quote:@"If you want to be successful, prepare to be doubted and tested"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 336
    boResult = [self insertDataQuote:336
                              author:@"Henry Ford"
                               quote:@"Whether you think you can, or think you can't - you're right"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 337
    boResult = [self insertDataQuote:337
                              author:@"Guy Kawasaki"
                               quote:@"Don't be discouraged by the size of your network - inspire one person and you are doing good"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 338
    boResult = [self insertDataQuote:338
                              author:@"Brian Tracy"
                               quote:@"Your self-image controls your performance; see yourself as confident and in complete control"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 339
    boResult = [self insertDataQuote:339
                              author:@"Brian Tracy"
                               quote:@"It is not failure itself that holds you back; it is the fear of failure that paralyzes you"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 340
    boResult = [self insertDataQuote:340
                              author:@"Zig Ziglar"
                               quote:@"You were born to win, but to be a winner, you must plan to win, prepare to win, and expect to win"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 341
    boResult = [self insertDataQuote:341
                              author:@"Unknown"
                               quote:@"If you are willing to do more than you are paid to do, eventually you will be paid to do more than you do"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 342
    boResult = [self insertDataQuote:342
                              author:@"Bo Bennett"
                               quote:@"The discipline you learn and character you build from setting and achieving a goal can be more valuable than the achievement of the goal itself"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 343
    boResult = [self insertDataQuote:343
                              author:@"Victor Kiam"
                               quote:@"Even if you fall on your face you’re still moving forward"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 344
    boResult = [self insertDataQuote:344
                              author:@"Benjamin Franklin"
                               quote:@"Well done is better than well said"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 345
    boResult = [self insertDataQuote:345
                              author:@"Wayne Dyer"
                               quote:@"Go for it now. The future is promised to no one"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 346
    boResult = [self insertDataQuote:346
                              author:@"William Butler Yeats"
                               quote:@"Do not wait to strike till the iron is hot; but make it hot by striking"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 347
    boResult = [self insertDataQuote:347
                              author:@"Mark Twain"
                               quote:@"I have never let my schooling interfere with my education"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 348
    boResult = [self insertDataQuote:348
                              author:@"Benjamin Franklin"
                               quote:@"If everyone is thinking alike, then no one is thinking"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 349
    boResult = [self insertDataQuote:349
                              author:@"Lorand Soares Szasz"
                               quote:@"Money run away from people who run after money"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 350
    boResult = [self insertDataQuote:350
                              author:@"Jim Rohn"
                               quote:@"Don't wish it was easier wish you were better. Don't wish for less problems wish for more skills. Don't wish for less challenge wish for more wisdom"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 351
    boResult = [self insertDataQuote:351
                              author:@"Lorand Soares Szasz"
                               quote:@"Give 100% in everything you do"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 352
    boResult = [self insertDataQuote:352
                              author:@"Martin Luther King, Jr."
                               quote:@"The time is always right to do what is right"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 353
    boResult = [self insertDataQuote:353
                              author:@"Martin Luther King, Jr."
                               quote:@"Everybody can be great ... because anybody can serve. You don't have to have a college degree to serve. You don't have to make your subject and verb agree to serve. You only need a heart full of grace. A soul generated by love"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 354
    boResult = [self insertDataQuote:354
                              author:@"Martin Luther King, Jr."
                               quote:@"If it falls to your lot to be a street sweeper, sweep streets like Michelangelo painted pictures, sweep streets like Beethoven composed music ... Sweep streets like Shakespeare wrote poetry. Sweep streets so well that all the host of heaven and earth will have to pause and say: Here lived a great street sweeper who swept his job well"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 355
    boResult = [self insertDataQuote:355
                              author:@"Lou Holtz"
                               quote:@"In this world you're either growing or you're dying so get in motion and grow"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 356
    boResult = [self insertDataQuote:356
                              author:@"T. Harv Eker"
                               quote:@"If you say you’re worthy, you are. If you say you’re not worthy, you’re not. Either way you will live into your story"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 357
    boResult = [self insertDataQuote:357
                              author:@"Steve Jobs"
                               quote:@"Stay hungry! Stay foolish"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 358
    boResult = [self insertDataQuote:358
                              author:@"Zig Ziglar"
                               quote:@"The definition of success is getting many of the things money can buy and all the things money can't buy"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 359
    boResult = [self insertDataQuote:359
                              author:@"Robin Sharma"
                               quote:@"Your I CAN is more important than your IQ"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 360
    boResult = [self insertDataQuote:360
                              author:@"Robin Sharma"
                               quote:@"We are all here for some special reason. Stop being a prisoner of your past. Become the architect of your future"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 361
    boResult = [self insertDataQuote:361
                              author:@"Robin Sharma"
                               quote:@"The smallest of actions is always better than the noblest of intentions"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 362
    boResult = [self insertDataQuote:362
                              author:@"Robin Sharma"
                               quote:@"Dream big. Start small. Act now"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 363
    boResult = [self insertDataQuote:363
                              author:@"Robin Sharma"
                               quote:@"Success on the outside means nothing unless you also have success within"
                            category:@"Health"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 364
    boResult = [self insertDataQuote:364
                              author:@"Robin Sharma"
                               quote:@"Getting lost along your path is a part of finding the path you are meant to be on"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 365
    boResult = [self insertDataQuote:365
                              author:@"Robin Sharma"
                               quote:@"I've heard that the best way to help poor people is to make sure you don't become one of them"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 366
    boResult = [self insertDataQuote:366
                              author:@"Robin Sharma"
                               quote:@"There are no mistakes in life, only lessons. There is no such thing as a negative experience, only opportunities to grow, learn and advance along the road of self-mastery .From struggle comes strength. Even pain can be a wonderful teacher"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 367
    boResult = [self insertDataQuote:367
                              author:@"Gary Vaynerchuk"
                               quote:@"People are chasing cash, not happiness. When you chase money, you're going to lose. You're just going to. Even if you get the money, you're not going to be happy"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 368
    boResult = [self insertDataQuote:368
                              author:@"Will Smith"
                               quote:@"We buy things we don't need with money we don't have to impress people we don't like"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 369
    boResult = [self insertDataQuote:369
                              author:@"Gary Vaynerchuk"
                               quote:@"Work! That’s how you get it"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 370
    boResult = [self insertDataQuote:370
                              author:@"Tony Robbins"
                               quote:@"The secret of success is learning how to use pain and pleasure instead of having pain and pleasure use you. If you do that, you’re in control of your life. If you don’t, life controls you"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 371
    boResult = [self insertDataQuote:371
                              author:@"Tony Robbins"
                               quote:@"Life is a gift, and it offers us the privilege, opportunity, and responsibility to give something back by becoming more"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 372
    boResult = [self insertDataQuote:372
                              author:@"Tony Robbins"
                               quote:@"Leaders spend 5% of their time on the problem & 95% of their time on the solution. Get over it & crush it"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 373
    boResult = [self insertDataQuote:373
                              author:@"Tony Robbins"
                               quote:@"One reason so few of us achieve what we truly want is that we never direct our focus; we never concentrate our power. Most people dabble their way through life, never deciding to master anything in particular"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 374
    boResult = [self insertDataQuote:374
                              author:@"Tony Robbins"
                               quote:@"The only problem we really have is we think we’re not supposed to have problems! Problems call us to higher level- – face & solve them now"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 375
    boResult = [self insertDataQuote:375
                              author:@"Tony Robbins"
                               quote:@"I discovered a long time ago that if I helped enough people get what they wanted, I would always get what I wanted and I would never have to worry"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 376
    boResult = [self insertDataQuote:376
                              author:@"Tony Robbins"
                               quote:@"Successful people ask better questions, and as a result, they get better answers"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 377
    boResult = [self insertDataQuote:377
                              author:@"Tony Robbins"
                               quote:@"It is not what we get. But who we become, what we contribute… that gives meaning to our lives"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 378
    boResult = [self insertDataQuote:378
                              author:@"Tony Robbins"
                               quote:@"We can change our lives. We can do, have, and be exactly what we wish"
                            category:@"Happiness"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 379
    boResult = [self insertDataQuote:379
                              author:@"Tony Robbins"
                               quote:@"It’s your unlimited power to care and to love that can make the biggest difference in the quality of your life"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 380
    boResult = [self insertDataQuote:380
                              author:@"Tony Robbins"
                               quote:@"If you don’t set a baseline standard for what you’ll accept in life, you’ll find it’s easy to slip into behaviors and attitudes or a quality of life that’s far below what you deserve"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 381
    boResult = [self insertDataQuote:381
                              author:@"Tony Robbins"
                               quote:@"Create a vision and never let the environment, other people’s beliefs, or the limits of what has been done in the past shape your decisions"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 382
    boResult = [self insertDataQuote:382
                              author:@"Tony Robbins"
                               quote:@"The path to success is to take massive, determined action"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 383
    boResult = [self insertDataQuote:383
                              author:@"Tony Robbins"
                               quote:@"It’s what you practice in private that you will be rewarded for in public"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 384
    boResult = [self insertDataQuote:384
                              author:@"Tony Robbins"
                               quote:@"When you are grateful fear disappears and abundance appears"
                            category:@"Gratitude"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 385
    boResult = [self insertDataQuote:385
                              author:@"Tony Robbins"
                               quote:@"Your income right now is a result of your standards, it is not the industry, it is not the economy"
                            category:@"Money"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 386
    boResult = [self insertDataQuote:386
                              author:@"Tony Robbins"
                               quote:@"There is no greatness without a passion to be great, whether it’s the aspiration of an athlete or an artist, a scientist, a parent, or a businessperson"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 387
    boResult = [self insertDataQuote:387
                              author:@"Tony Robbins"
                               quote:@"Commit to CANI! – Constant And Never-ending Improvement"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 388
    boResult = [self insertDataQuote:388
                              author:@"Mother Teresa"
                               quote:@"If everyone would sweep their own doorstep, the whole world will be clean"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 389
    boResult = [self insertDataQuote:389
                              author:@"George S. Clason"
                               quote:@"Proper preparation is the key to our success. Our acts can be no wiser than our thoughts. Our thinking can be no wiser than our understanding"
                            category:@"Education"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 390
    boResult = [self insertDataQuote:390
                              author:@"George S. Clason"
                               quote:@"Where the determination is, the way can be found"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 391
    boResult = [self insertDataQuote:391
                              author:@"Robin Sharma"
                               quote:@"Winning starts with beginning. Today’s a fine day to begin your best life"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 392
    boResult = [self insertDataQuote:392
                              author:@"Robin Sharma"
                               quote:@"Last year’s world-record is this year’s starting point"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 393
    boResult = [self insertDataQuote:393
                              author:@"Robin Sharma"
                               quote:@"What you now find easy, you once found difficult. Stay consistent. Do not stop"
                            category:@"Success2"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 394
    boResult = [self insertDataQuote:394
                              author:@"Robin Sharma"
                               quote:@"There are 2 economies: Income and Impact. Both matter. Because prosperity without philanthropy will leave you empty"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 395
    boResult = [self insertDataQuote:395
                              author:@"Robin Sharma"
                               quote:@"Life is too short to play small. Go big for the benefit of the world"
                            category:@"Success3"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 396
    boResult = [self insertDataQuote:396
                              author:@"Robin Sharma"
                               quote:@"True power is being an instrument of service. And seeing your work as a ministry for the benefit of humanity. Watches and handbags, titles and cars, social standing and public applause won’t matter. At the end"
                            category:@"Giving"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 397
    boResult = [self insertDataQuote:397
                              author:@"George Bernard Shaw"
                               quote:@"The reasonable man adapts himself to the world. The unreasonable one persists in trying to adapt the world to himself. Therefore, all progress depends on the unreasonable man"
                            category:@"Success"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 398
    boResult = [self insertDataQuote:398
                              author:@"Will Arnett"
                               quote:@"I am happy because I'm grateful. I choose to be grateful. That gratitude allows me to be happy"
                            category:@"Gratitude"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 399
    boResult = [self insertDataQuote:399
                              author:@"Zig Ziglar"
                               quote:@"Gratitude is the healthiest of all human emotions. The more you express gratitude for what you have, the more likely you will have even more to express gratitude for"
                            category:@"Gratitude"];
    if(boResult == FALSE)
        return FALSE;
    
    // quote id = 400
    boResult = [self insertDataQuote:400
                              author:@"Willie Nelson"
                               quote:@"When I started counting my blessings, my whole life turned around"
                            category:@"Gratitude"];
    if(boResult == FALSE)
        return FALSE;
    
    NSLog(@"# Quote database successfully populated!\n");
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
    boResult = [self insertDataAdvice:4 advice:@"Be grateful for what you have! Gratitude is the most important ingredient in a successful life!"];
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
    boResult = [self insertDataAdvice:7 advice:@"Keep striving! Don’t quit! Sooner or later, you will reach your goal"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 8
    boResult = [self insertDataAdvice:8 advice:@"Love yourself! You are unique and wonderful in your own way!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 9
    boResult = [self insertDataAdvice:9 advice:@"If you want people to enjoy your success begin by enjoying others success!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 10
    boResult = [self insertDataAdvice:10 advice:@"Dream big, work hard!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 11
    boResult = [self insertDataAdvice:11 advice:@"Build good habits! Build a good habit each month. After 6 months, you'll have 6 good habits that will make you successful."];
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
    boResult = [self insertDataAdvice:14 advice:@"Celebrate other success! You will surround yourself with success!"];
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
    boResult = [self insertDataAdvice:17 advice:@"Take care of your health! It's the only way to perform at your best!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 18
    boResult = [self insertDataAdvice:18 advice:@"Do things that make you happy!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 19
    boResult = [self insertDataAdvice:19 advice:@"Spend time with a children! Spend 1 hour per week playing with a child in need. You have no idea how much it means to him."];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 20
    boResult = [self insertDataAdvice:20 advice:@"Before going to bed, write in your journal 3 things you are grateful for! This is one of the most recommended ways to practice gratitude everyday!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 21
    boResult = [self insertDataAdvice:21 advice:@"Give back to others! If you can’t give the gift of money, give the gift of time!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 22
    boResult = [self insertDataAdvice:22 advice:@"Embrace the change! It's the only way you learn and grow as a person"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 23
    boResult = [self insertDataAdvice:23 advice:@"Step out of your comfort zone! Try new things!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 24
    boResult = [self insertDataAdvice:24 advice:@"Don’t watch the news, they are full of negativity! Read a book instead!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 25
    boResult = [self insertDataAdvice:25 advice:@"Compliment others and you will receive many more in return!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 26
    boResult = [self insertDataAdvice:26 advice:@"Keep a journal! Begin by writing each night three things you are grateful for that happened that day!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 27
    boResult = [self insertDataAdvice:27 advice:@"You are the only responsible for your happiness! No one in charge of your life!"];
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
    boResult = [self insertDataAdvice:35 advice:@"Realise that life is a school and you are here to learn! Every failure turns into success if your learn from it! "];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 36
    boResult = [self insertDataAdvice:36 advice:@"Smile and laugh more! These are key ingredients for a fulfilled life!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 37
    boResult = [self insertDataAdvice:37 advice:@"Don’t compare your life to others. You have no idea what their journey is all about!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 38
    boResult = [self insertDataAdvice:38 advice:@"Enjoy life’s each moment! You will not live for ever, so till you are alive, enjoy every moment of your life from the core of your heart."];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 39
    boResult = [self insertDataAdvice:39 advice:@"Love yourself because once you accept who you are, you can focus your energy on other matters and people in your life!"];
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
    boResult = [self insertDataAdvice:57 advice:@"You attract what you are! Be a kind person and people will be kind to you!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 58
    boResult = [self insertDataAdvice:58 advice:@"Know when to speak up, know when to stay quiet!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 59
    boResult = [self insertDataAdvice:59 advice:@"Stay away from toxic people! They are draining your energy!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 60
    boResult = [self insertDataAdvice:60 advice:@"Talk less, do more! The world reached an unacceptable level of complaining!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 61
    boResult = [self insertDataAdvice:61 advice:@"You are beautiful! Love yourself!"];
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
    boResult = [self insertDataAdvice:66 advice:@"You are ready for the next step! Even if you fail, you will learn just from trying!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 67
    boResult = [self insertDataAdvice:67 advice:@"Help those around you!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 68
    boResult = [self insertDataAdvice:68 advice:@"Never let success get to your head! Stay humble!"];
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
    boResult = [self insertDataAdvice:76 advice:@"Get up early! "];
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
    boResult = [self insertDataAdvice:82 advice:@"Listen to podcasts and audiobooks on your daily commute!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 83
    boResult = [self insertDataAdvice:83 advice:@"Make time to exercise! Take care of your body when you are young and he will take care of you when you will be old!"];
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
    boResult = [self insertDataAdvice:86 advice:@"Your time is limited, use it wisely! Do not spend your best hours of your life watching TV and scrolling on Facebook!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 87
    boResult = [self insertDataAdvice:87 advice:@"Everything will workout! Just work hard and have faith!"];
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
    boResult = [self insertDataAdvice:90 advice:@"Make people feel important! Treat people the way you want to be treated!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 91
    boResult = [self insertDataAdvice:91 advice:@"Get good and skilled at what you do! Read books, articles, go to trainings, do everything that will improve your knowledge in your field. "];
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
    boResult = [self insertDataAdvice:99 advice:@"Let go of your ego! Practice forgiveness and honesty!"];
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
    boResult = [self insertDataAdvice:108 advice:@"Maintain a monthly budget! The way the universe works is if you manage your money, you will get more. If you mismanage your money, you will not get any more! Read more about Harv Ekker's money jar system!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 109
    boResult = [self insertDataAdvice:109 advice:@"Speak lovingly to yourself!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 110
    boResult = [self insertDataAdvice:110 advice:@"Never stop learning! Successful people are constantly learning!"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 111
    boResult = [self insertDataAdvice:111 advice:@"Never stop growing! Be better than yesterday!"];
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
    boResult = [self insertDataAdvice:114 advice:@"Don’t be afraid to fail! Fail big and you will succceed bigger!"];
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
    boResult = [self insertDataAdvice:120 advice:@"Read something inspirational right before going to bed and after waking up. You could start with this app :) !"];
    if(boResult == FALSE)
        return FALSE;
    
    // advice id = 121
    boResult = [self insertDataAdvice:121 advice:@"Say no to distractions!"];
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
    boResult = [self insertDataAdvice:127 advice:@"Sell your TV! Buy books!"];
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
    
    NSLog(@"# Advices database successfully populated!");
    return TRUE;
}

@end
