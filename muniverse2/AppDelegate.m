//
//  AppDelegate.m
//  muniverse2
//
//  Created by Nick O'Neill on 7/9/12.
//  Copyright (c) 2012 Nick O'Neill. All rights reserved.
//

#import "AppDelegate.h"
#import "Line.h"
#import "Stop.h"
#import "Subway.h"
#import "LoadingViewController.h"

@implementation AppDelegate

@synthesize window;

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
 //   [self customizeAppearance];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self checkForData];
    });
    
    [self setWindow:[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];
    
    // our loading screen is not in the base storyboard, it's just a standalone nib
    self.loading = [[LoadingViewController alloc] initWithNibName:@"LoadingViewController" bundle:nil];
    
    [self.window setRootViewController:self.loading];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"becameActive" object:nil];
}

- (void)checkForData
{
    // if we have not set the completion flag yet, or if its out of date, add the data
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"muniversedata" ofType:@"json"];
    
    if ([[defaults objectForKey:@"dataBuildDate"] isKindOfClass:[NSDate class]]) {
        // every start other than the first will come here, but only do extra processing if we have upgraded muni data
        
        NSDate *buildDate = [defaults objectForKey:@"dataBuildDate"];
        
        NSError *error;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:jsonPath] options:NSJSONReadingAllowFragments error:&error];
        
        if (error) {
            NSLog(@"error parsing json: %@",[error localizedDescription]);
        } else {
            NSDate *jsonDate = [NSDate dateWithTimeIntervalSince1970:[[jsonData objectForKey:@"BuildDate"] integerValue]];
            
            if ([buildDate laterDate:jsonDate] == jsonDate) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.loading.loadingLabel setHidden:NO];
                });
                
                [self removeAllEntitiesOfType:@"Stop"];
                [self removeAllEntitiesOfType:@"Line"];
                [self removeAllEntitiesOfType:@"Subway"];
                [self addJsonData:jsonData];
            }
        }
    } else {
        // likely the first start for the app
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.loading.loadingLabel setHidden:NO];
        });
        
        NSError *error;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:jsonPath] options:NSJSONReadingAllowFragments error:&error];
        if (error != nil) {
            NSLog(@"error parsing json: %@",[error localizedDescription]);
        } else {
            
            // new users should not have this data, but potentially a failed first startup could half-fill them
            [self removeAllEntitiesOfType:@"Stop"];
            [self removeAllEntitiesOfType:@"Line"];
            [self removeAllEntitiesOfType:@"Subway"];
            
            // add new data
            [self addJsonData:jsonData];
        }
    }
    
    // we're all set, bring up the storyboard on the main thread
    dispatch_sync(dispatch_get_main_queue(), ^{
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"base" bundle:nil];
        UITabBarController *mainViewController = [storyboard instantiateInitialViewController];
        
        [self.window setRootViewController:mainViewController];
    });
}

- (void)removeAllEntitiesOfType:(NSString *)entityDescription
{
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:entityDescription];
    
    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetch error:&error];
    
    for (NSManagedObject *managedObject in results) {
        [self.managedObjectContext deleteObject:managedObject];
    }
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"there was an issue removing all %@: %@",entityDescription,[error localizedDescription]);
    }
}

- (void)customizeAppearance
{
    UIImage *navBarTexture = [UIImage imageNamed:@"navBarLeather.png"];
    [[UINavigationBar appearance] setBackgroundImage:navBarTexture forBarMetrics:UIBarMetricsDefault];
    
    UIImage *navBarButton = [UIImage imageNamed:@"navBarButtonLeatherNormal.png"];
    [[UIBarButtonItem appearance] setBackgroundImage:navBarButton forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}


- (void)addJsonData:(NSDictionary *)data
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    
    // the stop cache improves this process by not forcing a core data lookup when we later want to add stops to their associated lines
    NSMutableDictionary *stopCache = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < [[data objectForKey:@"StopList"] count]; i++) {
        NSDictionary *stopDict = [[data objectForKey:@"StopList"] objectAtIndex:i];
        
        Stop *stop = [NSEntityDescription insertNewObjectForEntityForName:@"Stop" inManagedObjectContext:moc];
        [stop setValue:[stopDict objectForKey:@"Title"] forKey:@"name"];
        [stop setValue:[stopDict objectForKey:@"Tag"] forKey:@"tag"];
        [stop setValue:[stopDict objectForKey:@"StopId"] forKey:@"stopId"];
        [stop setValue:[stopDict objectForKey:@"Lat"] forKey:@"lat"];
        [stop setValue:[stopDict objectForKey:@"Lon"] forKey:@"lon"];
        
        [stopCache setObject:stop forKey:[stopDict objectForKey:@"Tag"]];
    }
    
    for (int i = 0; i < [[data objectForKey:@"LineList"] count]; i++) {
        NSDictionary *lineDict = [[data objectForKey:@"LineList"] objectAtIndex:i];
        
        Line *line = [NSEntityDescription insertNewObjectForEntityForName:@"Line" inManagedObjectContext:moc];
        [line setValue:[lineDict objectForKey:@"Title"] forKey:@"name"];
        [line setValue:[lineDict objectForKey:@"Short"] forKey:@"shortname"];
        [line setValue:[lineDict objectForKey:@"IsHistoric"] forKey:@"historic"];
        [line setValue:[lineDict objectForKey:@"IsMetro"] forKey:@"metro"];
        [line setValue:[lineDict objectForKey:@"IBTag"] forKey:@"inboundTags"];
        [line setValue:[lineDict objectForKey:@"OBTag"] forKey:@"outboundTags"];
        [line setValue:[lineDict objectForKey:@"InboundDesc"] forKey:@"inboundDesc"];
        [line setValue:[lineDict objectForKey:@"OutboundDesc"] forKey:@"outboundDesc"];
        [line setValue:[lineDict objectForKey:@"FullDesc"] forKey:@"fullDesc"];
        [line setValue:[lineDict objectForKey:@"AllLinesSort"] forKey:@"allLinesSort"];
        
        NSString *stopsort = @"";
        if ([lineDict objectForKey:@"InboundTags"] != [NSNull null]) {
            for (int j = 0; j < [[lineDict objectForKey:@"InboundTags"] count]; j++) {
                int stoptag = [[[lineDict objectForKey:@"InboundTags"] objectAtIndex:j] intValue];
                // add to sort string
                stopsort = [stopsort stringByAppendingFormat:@",%d",stoptag];
                
                // add stop from cache
                Stop *stop = [stopCache objectForKey:[NSNumber numberWithInt:stoptag]];
                [line addInboundStopsObject:stop];
            }
            [line setValue:stopsort forKey:@"inboundSort"];
        }
        
        stopsort = @"";
        if ([lineDict objectForKey:@"OutboundTags"] != [NSNull null]) {
            for (int j = 0; j < [[lineDict objectForKey:@"OutboundTags"] count]; j++) {
                int stoptag = [[[lineDict objectForKey:@"OutboundTags"] objectAtIndex:j] intValue];
                // add to sort string
                stopsort = [stopsort stringByAppendingFormat:@",%d",stoptag];
                
                // add stop from cache
                Stop *stop = [stopCache objectForKey:[NSNumber numberWithInt:stoptag]];
                [line addOutboundStopsObject:stop];
            }
            [line setValue:stopsort forKey:@"outboundSort"];
        }
    }
    
    for (int i = 0; i < [[data objectForKey:@"SubwayList"] count]; i++) {
        NSDictionary *subwayDict = [[data objectForKey:@"SubwayList"] objectAtIndex:i];
        
        Subway *subway = [NSEntityDescription insertNewObjectForEntityForName:@"Subway" inManagedObjectContext:moc];
        [subway setValue:[subwayDict objectForKey:@"Name"] forKey:@"name"];
        [subway setValue:[stopCache objectForKey:[subwayDict objectForKey:@"IBStopTag"]] forKey:@"inboundStop"];
        [subway setValue:[stopCache objectForKey:[subwayDict objectForKey:@"OBStopTag"]] forKey:@"outboundStop"];
        [subway setValue:[subwayDict objectForKey:@"AboveGround"] forKey:@"isAboveGround"];
        [subway setValue:[subwayDict objectForKey:@"Order"] forKey:@"order"];
    }
    
    NSError *err;
    if (![moc save:&err]) {
        NSLog(@"Whoops, error saving demo data: %@",[err localizedDescription]);
    }
    
    // build date serves as proof of complete data addition, as well as an upgrade point
    int time = [[data objectForKey:@"BuildDate"] integerValue];
    NSDate *dataBuildDate = [NSDate dateWithTimeIntervalSince1970:time];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:dataBuildDate forKey:@"dataBuildDate"];
    [defaults synchronize];
}

- (BOOL)coreDataHasEntriesForEntityName:(NSString *)entityName {
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:req error:&error];
    if (!results) {
        NSLog(@"Fetch error: %@", error);
        abort();
    }
    if ([results count] == 0) {
        return NO;
    }
    return YES;
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
//    [NSFetchedResultsController deleteCacheWithName:@"Root"];
    
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CoreMuni" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"coremuni.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
