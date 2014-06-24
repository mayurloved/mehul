	
#import "SKDatabase.h"
#import "AppDelegate.h"

@implementation SKDatabase

@synthesize delegate;
@synthesize dbh;
@synthesize dynamic;

// Two ways to init: one if you're just SELECTing from a database, one if you're UPDATing
// and or INSERTing

- (id)initWithReadOnlyFile:(NSString *)dbFile
{
	if (self = [super init])
    {
        NSString *paths = [[NSBundle mainBundle] resourcePath];
		NSString *path = [paths stringByAppendingPathComponent:dbFile];
		NSLog(@"Opening database %@", path);
		
		int result = sqlite3_open([path UTF8String], &dbh);
		NSAssert1(SQLITE_OK == result, NSLocalizedStringFromTable(@"Unable to open the sqlite database (%@).", @"Database", @""), [NSString stringWithUTF8String:sqlite3_errmsg(dbh)]);	
		self.dynamic = NO;
	}
	
	return self;	
}

- (id)initWithFile:(NSString *)dbFile
{
	if (self = [super init])
    {
		
		NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *docDir = [docPaths objectAtIndex:0];
		NSString *docPath = [docDir stringByAppendingPathComponent:dbFile];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if (![fileManager fileExistsAtPath:docPath]) {
			
			NSString *origPaths = [[NSBundle mainBundle] resourcePath];
			NSString *origPath = [origPaths stringByAppendingPathComponent:dbFile];
			
			NSError *error;
			int success = [fileManager copyItemAtPath:origPath toPath:docPath error:&error];			
			NSAssert1(success,[NSString stringWithString:@"Failed to copy database into dynamic location"],error);
		}
		int result = sqlite3_open([docPath UTF8String], &dbh);
		NSAssert1(SQLITE_OK == result, NSLocalizedStringFromTable(@"Unable to open the sqlite database (%@).", @"Database", @""), [NSString stringWithUTF8String:sqlite3_errmsg(dbh)]);	
		self.dynamic = YES;
	}
	
	return self;	
}

- (id)initWithData:(NSData *)data andFile:(NSString *)dbFile {
	if (self = [super init]) {
		
		NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *docDir = [docPaths objectAtIndex:0];
		NSString *docPath = [docDir stringByAppendingPathComponent:dbFile]; 
		bool success = [data writeToFile:docPath atomically:YES];
		
		NSAssert1(success,[NSString stringWithString:@"Failed to save database into documents path"], nil);
		
		int result = sqlite3_open([docPath UTF8String], &dbh);
		NSAssert1(SQLITE_OK == result, NSLocalizedStringFromTable(@"Unable to open the sqlite database (%@).", @"Database", @""), [NSString stringWithUTF8String:sqlite3_errmsg(dbh)]);	
		self.dynamic = YES;
	}
	
	return self;	
}

// Users should never need to call prepare

- (sqlite3_stmt *)prepare:(NSString *)sql {
	
	const char *utfsql = [sql UTF8String];
	
	sqlite3_stmt *statement;
	
	if (sqlite3_prepare([self dbh],utfsql,-1,&statement,NULL) == SQLITE_OK) {
		return statement;
	} else {
		return 0;
	}
}

// Three ways to lookup results: for a variable number of responses, for a full row
// of responses, or for a singular bit of data

- (NSArray *)lookupAllForSQL:(NSString *)sql
{
	sqlite3_stmt *statement;
	id result;
	NSMutableArray *thisArray = [[NSMutableArray alloc]init];
    statement = [self prepare:sql];
	if (statement) {
		while (sqlite3_step(statement) == SQLITE_ROW) {	
			NSMutableDictionary *thisDict = [NSMutableDictionary dictionaryWithCapacity:4];
			for (int i = 0 ; i < sqlite3_column_count(statement) ; i++)
            {
				if(sqlite3_column_type(statement,i) == SQLITE_NULL)
                {
					continue;
				}
				if (sqlite3_column_decltype(statement,i) != NULL &&
					strcasecmp(sqlite3_column_decltype(statement,i),"Boolean") == 0)
                {
					result = [NSNumber numberWithBool:(BOOL)sqlite3_column_int(statement,i)];
				}
//                else if (sqlite3_column_type(statement,i) == SQLITE_INTEGER) {
//					result = [NSNumber numberWithInt:(int)sqlite3_column_int(statement,i)];
//				}
                else if (sqlite3_column_type(statement,i) == SQLITE_FLOAT) {
					result = [NSNumber numberWithFloat:(float)sqlite3_column_double(statement,i)];					
				}
                else {
                    
					if((char *)sqlite3_column_text(statement,i) != NULL){
                        result = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement,i)];
                       // result = [result stringByReplacingOccurrencesOfString:@"\'" withString:@"'"];
                        [thisDict setObject:[result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                     forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement,i)]];
                        [result release];
                        result = nil;
					}
				}
				if (result) {
					[thisDict setObject:[result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
								 forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement,i)]];
				}
			}
			[thisArray addObject:[NSDictionary dictionaryWithDictionary:thisDict]];
		}
	}
	sqlite3_finalize(statement);
	return thisArray;
}

- (NSDictionary *)lookupRowForSQL:(NSString *)sql {
	sqlite3_stmt *statement;
	id result;
	NSMutableDictionary *thisDict = [NSMutableDictionary dictionaryWithCapacity:4];
	if ((statement = [self prepare:sql])) {
		if (sqlite3_step(statement) == SQLITE_ROW) {	
			for (int i = 0 ; i < sqlite3_column_count(statement) ; i++) {
				if (strcasecmp(sqlite3_column_decltype(statement,i),"Boolean") == 0) {
					result = [NSNumber numberWithBool:(BOOL)sqlite3_column_int(statement,i)];
				} else if (sqlite3_column_type(statement, i) == SQLITE_TEXT) {
					result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,i)];
				} else if (sqlite3_column_type(statement,i) == SQLITE_INTEGER) {
					result = [NSNumber numberWithInt:(int)sqlite3_column_int(statement,i)];
				} else if (sqlite3_column_type(statement,i) == SQLITE_FLOAT) {
					result = [NSNumber numberWithFloat:(float)sqlite3_column_double(statement,i)];					
				} else {
					if((char *)sqlite3_column_text(statement,i) != NULL){
						result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,i)];
					}
				}
				if (result) {
					[thisDict setObject:result
								 forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement,i)]];
				}
			}
		}
	}
	sqlite3_finalize(statement);
	return thisDict;
}

- (id)lookupColForSQL:(NSString *)sql {
	
	sqlite3_stmt *statement;
	id result;
	if ((statement = [self prepare:sql])) {
		if (sqlite3_step(statement) == SQLITE_ROW) {		
			 if (sqlite3_column_type(statement, 0) == SQLITE_TEXT) {
				result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,0)];
			} else if (sqlite3_column_type(statement,0) == SQLITE_FLOAT) {
				result = [NSNumber numberWithDouble:(double)sqlite3_column_double(statement,0)];
			} else {
				result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,0)];
			}
		}
	}
	sqlite3_finalize(statement);
    
    NSLog(@"result -------------> %@",result );
    NSLog(@"result -------------> %d",[result integerValue]);
	return result;
	
}

// Simple use of COUNTS, MAX, etc.

- (int)lookupCountWhere:(NSString *)where forTable:(NSString *)table {
	
	int tableCount = 0;
	NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE %@",
					 table,where];    	
	sqlite3_stmt *statement;
	
	if ((statement = [self prepare:sql])) {
		if (sqlite3_step(statement) == SQLITE_ROW) {		
			tableCount = sqlite3_column_int(statement,0);
		}
	}
	sqlite3_finalize(statement);
	return tableCount;
	
}
- (int)lookupMax:(NSString *)key forTable:(NSString *)table{
	
	int tableMax = 0;
	NSString *sql = [NSString stringWithFormat:@"SELECT MAX(%@) FROM %@" ,
					 key,table];
	sqlite3_stmt *statement;
	if ((statement = [self prepare:sql])) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
			tableMax = sqlite3_column_int(statement,0);
		}
	}
	sqlite3_finalize(statement);
	return tableMax;
	
}

- (int)lookupMax:(NSString *)key Where:(NSString *)where forTable:(NSString *)table {
	
	int tableMax = 0;
	NSString *sql = [NSString stringWithFormat:@"SELECT MAX(%@) FROM %@ WHERE %@",
					 key,table,where];
	sqlite3_stmt *statement;
	if ((statement = [self prepare:sql])) {
		if (sqlite3_step(statement) == SQLITE_ROW) {		
			tableMax = sqlite3_column_int(statement,0);
		}
	}
	sqlite3_finalize(statement);
	return tableMax;
	
}

- (int)lookupSum:(NSString *)key Where:(NSString *)where forTable:(NSString *)table {
	
	int tableSum = 0;
	NSString *sql = [NSString stringWithFormat:@"SELECT SUM(%@) FROM %@ WHERE %@",
					 key,table,where];    	
	sqlite3_stmt *statement;
	if ((statement = [self prepare:sql])) {
		if (sqlite3_step(statement) == SQLITE_ROW) {		
			tableSum = sqlite3_column_int(statement,0);
		}
	}
	sqlite3_finalize(statement);
	return tableSum;
}


#pragma mark add playlist

-(void) addPlayList:(MPMediaItemCollection *)mediaCollection classid:(int)classid count:(int)order
{
    NSLog(@"count %d",[mediaCollection count]);
    
        for (int i = 0; i< [mediaCollection count]; i++)
        {
         //   order++;
            
            NSString *strPersistanceID = nil;
            NSInteger dur = 0;
            NSString *title, *artist;
            if ([[mediaCollection.items objectAtIndex:i] isKindOfClass:[MPMediaItem class]])
            {
                strPersistanceID = [NSString stringWithFormat:@"%@",[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyPersistentID]];
                dur = [[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyPlaybackDuration]integerValue];
                title = [NSString stringWithFormat:@"%@",[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyTitle]];
                artist = [NSString stringWithFormat:@"%@",[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyArtist]] ;
                
            }
            else if([[mediaCollection.items objectAtIndex:i] isKindOfClass:[DBMetadata class]])
            {
                DBMetadata *file = [mediaCollection.items objectAtIndex:i];
                dur = 0;
                title = [NSString stringWithFormat:@"%@",file.filename];
                artist = @"";
                strPersistanceID = [NSString stringWithFormat:@"dropbox-%@",file.filename];
            }else{
                strPersistanceID = @"";
                dur = [[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyPlaybackDuration]integerValue];
                title = [NSString stringWithFormat:@"%@",[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyTitle]];
                artist = [NSString stringWithFormat:@"%@",[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyArtist]];
            }
            
            NSLog(@"i->%d",i);
            
            NSLog(@"Title ---> %@, order %d",title,order);
            
            ///-------------------
            AppDelegate *app = [AppDelegate delegate];
            
           int orderno = [app.aryAllSongsToAddInClass indexOfObject:[mediaCollection.items objectAtIndex:i]] + order;
            
            NSDictionary *dict = [[NSDictionary alloc]initWithObjectsAndKeys:[NSString stringWithFormat:@"%d",classid], @"classid", strPersistanceID,@"pid",[NSString stringWithFormat:@"%d",dur],@"duration",title,@"title",artist,@"artist",[NSString stringWithFormat:@"%d",orderno],@"orderno", nil];
            [self insertDictionary:dict forTable:@"tblclasstrack"];
            ///-------------------
           
        }
    
	return;
}

-(void) addPlayList:(MPMediaItemCollection *)mediaCollection classid:(int)classid orderNumber:(int)order
{
    
    for (int i = 0; i< [mediaCollection count]; i++)
    {
        //   order++;
        
        NSString *strPersistanceID = nil;
        NSInteger dur = 0;
        NSString *title, *artist;
        if ([[mediaCollection.items objectAtIndex:i] isKindOfClass:[MPMediaItem class]])
        {
            strPersistanceID = [NSString stringWithFormat:@"%@",[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyPersistentID]];
            dur = [[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyPlaybackDuration]integerValue];
            title = [NSString stringWithFormat:@"%@",[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyTitle]];
            artist = [NSString stringWithFormat:@"%@",[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyArtist]] ;
            
        }
        else if([[mediaCollection.items objectAtIndex:i] isKindOfClass:[DBMetadata class]])
        {
            DBMetadata *file = [mediaCollection.items objectAtIndex:i];
            dur = 0;
            title = [NSString stringWithFormat:@"%@",file.filename];
            artist = @"";
            strPersistanceID = [NSString stringWithFormat:@"dropbox-%@",file.filename];
        }else{
            strPersistanceID = @"";
            dur = [[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyPlaybackDuration]integerValue];
            title = [NSString stringWithFormat:@"%@",[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyTitle]];
            artist = [NSString stringWithFormat:@"%@",[[mediaCollection.items objectAtIndex:i] valueForProperty:MPMediaItemPropertyArtist]];
        }
        
        NSLog(@"i->%d",i);
        
        NSLog(@"Title ---> %@, order %d",title,order);
        
        
        NSDictionary *dict = [[NSDictionary alloc]initWithObjectsAndKeys:[NSString stringWithFormat:@"%d",classid], @"classid", strPersistanceID,@"pid",[NSString stringWithFormat:@"%d",dur],@"duration",title,@"title",artist,@"artist",[NSString stringWithFormat:@"%d",order],@"orderno", nil];
        [self insertDictionary:dict forTable:@"tblclasstrack"];
        ///-------------------
        
    }
    
	return;
}
#pragma mark ----------------

// INSERTing and UPDATing

- (void)insertArray:(NSArray *)dbData forTable:(NSString *)table {
	
	NSMutableString *sql = [NSMutableString stringWithCapacity:16];
	[sql appendFormat:@"INSERT INTO %@ (",table];
	
	for (int i = 0 ; i < [dbData count] ; i++) {
		[sql appendFormat:@"%@",[[dbData objectAtIndex:i] objectForKey:@"key"]];
		if (i + 1 < [dbData count]) {
			[sql appendFormat:@", "];
		}
	}
	[sql appendFormat:@") VALUES("];
	for (int i = 0 ; i < [dbData count] ; i++) {
		if ([[[dbData objectAtIndex:i] objectForKey:@"value"] intValue]) {
			[sql appendFormat:@"%@",[[[dbData objectAtIndex:i] objectForKey:@"value"] intValue]];
		} else {
			[sql appendFormat:@"'%@'",[[dbData objectAtIndex:i] objectForKey:@"value"]];
		}
		if (i + 1 < [dbData count]) {
			[sql appendFormat:@", "];
		}
	}
	[sql appendFormat:@")"];
	[self runDynamicSQL:sql forTable:table];
}

- (void)insertDictionary:(NSDictionary *)dbData forTable:(NSString *)table {
	
	NSMutableString *sql = [NSMutableString stringWithCapacity:16];
	[sql appendFormat:@"INSERT INTO %@ (",table];
	
	NSArray *dataKeys = [dbData allKeys];
	for (int i = 0 ; i < [dataKeys count] ; i++) {
		[sql appendFormat:@"%@",[dataKeys objectAtIndex:i]];
		if (i + 1 < [dbData count]) {
			[sql appendFormat:@", "];
		}
	}
	
	[sql appendFormat:@") VALUES("];
	for (int i = 0 ; i < [dataKeys count] ; i++)
    {
//		if ([[dbData objectForKey:[dataKeys objectAtIndex:i]] intValue]) {
//			NSString *str = [NSString stringWithFormat:@"%@",[dbData objectForKey:[dataKeys objectAtIndex:i]]];	
//			NSArray *arr = [str componentsSeparatedByString:@"/"];
//			if ([arr count]>2) {
//				[sql appendFormat:@"'%@'",[dbData objectForKey:[dataKeys objectAtIndex:i]]];
//			}
//			else {
//				[sql appendFormat:@"%@",[dbData objectForKey:[dataKeys objectAtIndex:i]]];
//			}
//		}
//        else {
        
        NSString *str = [dbData objectForKey:[dataKeys objectAtIndex:i]];
       
        if ([str isKindOfClass:[NSString class]]) {
             str = [str stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
        }
       
        [sql appendFormat:@"'%@'",str ];
        
		//}
        
		if (i + 1 < [dbData count]) {
			[sql appendFormat:@", "];
		}
	}
	
	[sql appendFormat:@")"];
    NSLog(@"sql %@",sql);
	[self runDynamicSQL:sql forTable:table];
}

- (void)updateArray:(NSArray *)dbData forTable:(NSString *)table { 
	[self updateArray:dbData forTable:table where:NULL];
}

- (void)updateArray:(NSArray *)dbData forTable:(NSString *)table where:(NSString *)where {
	
	NSMutableString *sql = [NSMutableString stringWithCapacity:16];
	[sql appendFormat:@"UPDATE %@ SET ",table];
	
	for (int i = 0 ; i < [dbData count] ; i++) {
		if ([[[dbData objectAtIndex:i] objectForKey:@"value"] intValue]) {
			[sql appendFormat:@"%@=%@",
			 [[dbData objectAtIndex:i] objectForKey:@"key"],
			 [[dbData objectAtIndex:i] objectForKey:@"value"]];
		} else {
			[sql appendFormat:@"%@='%@'",
			 [[dbData objectAtIndex:i] objectForKey:@"key"],
			 [[dbData objectAtIndex:i] objectForKey:@"value"]];
		}		
		if (i + 1 < [dbData count]) {
			[sql appendFormat:@", "];
		}
	}
	if (where != NULL) {
		[sql appendFormat:@" WHERE %@",where];
	} else {
		[sql appendFormat:@" WHERE 1",where];
	}		
	[self runDynamicSQL:sql forTable:table];
}

- (void)updateDictionary:(NSDictionary *)dbData forTable:(NSString *)table { 
	[self updateDictionary:dbData forTable:table where:NULL];
}

- (void)updateDictionary:(NSDictionary *)dbData forTable:(NSString *)table where:(NSString *)where {
	
	NSMutableString *sql = [NSMutableString stringWithCapacity:16];
	[sql appendFormat:@"UPDATE %@ SET ",table];
	
	NSArray *dataKeys = [dbData allKeys];
	for (int i = 0 ; i < [dataKeys count] ; i++) {
//		if ([[dbData objectForKey:[dataKeys objectAtIndex:i]] intValue]) {
//			[sql appendFormat:@"%@=%@",
//			 [dataKeys objectAtIndex:i],
//			 [dbData objectForKey:[dataKeys objectAtIndex:i]]];
//		} else {
        
        NSString *str = [dbData objectForKey:[dataKeys objectAtIndex:i]];
        
        if ([str isKindOfClass:[NSString class]]) {
            str = [str stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
        }
        
        [sql appendFormat:@"%@='%@'",[dataKeys objectAtIndex:i], str];
		//}
		if (i + 1 < [dbData count]) {
			[sql appendFormat:@", "];
		}
	}
	if (where != NULL) {
		[sql appendFormat:@" WHERE %@",where];
	}
	[self runDynamicSQL:sql forTable:table];
}

- (void)updateSQL:(NSString *)sql forTable:(NSString *)table {
	[self runDynamicSQL:sql forTable:table];
}

- (void)deleteWhere:(NSString *)where forTable:(NSString *)table {
	
	NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@",
					 table,where];
	[self runDynamicSQL:sql forTable:table];
}

- (void) deleteAllFrom:(NSString *)table{
	NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@", table];
	[self runDynamicSQL:sql forTable:table];
}

// INSERT/UPDATE/DELETE Subroutines

- (BOOL)runDynamicSQL:(NSString *)sql forTable:(NSString *)table {
	
    NSLog(@"sql %@",sql);
	int result = 0;
	NSAssert1(self.dynamic == 1,[NSString stringWithString:@"Tried to use a dynamic function on a static database"],NULL);
	sqlite3_stmt *statement;
	if ((statement = [self prepare:sql])) {
		result = sqlite3_step(statement);
    }		
	sqlite3_finalize(statement);
	if (result) {
		if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(databaseTableWasUpdated:)]) {
			[delegate databaseTableWasUpdated:table];
		}	
        NSLog(@"done");
		return YES;
	} else {
		return NO;
	}
	
}

- (NSString *)escapeString:(NSString *)dirtyString{
	NSString *cleanString = [dirtyString stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
	[cleanString autorelease];
	
	return cleanString;
}

// requirements for closing things down

- (void)dealloc {
	[self close];
	[delegate release];
	[super dealloc];
}

- (void)close {
	
	if (dbh) {
		sqlite3_close(dbh);
	}
}

@end