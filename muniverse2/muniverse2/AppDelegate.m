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

@implementation AppDelegate

@synthesize window,subway;

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if (![self coreDataHasEntriesForEntityName:@"Stop"]) {
        [self addDemoData];
    }
        
    return YES;
}

- (void)addDemoData
{
    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"muniversedata" ofType:@"json"];
    NSDictionary *jsonData = [NSDictionary dictionaryWithContentsOfFile:jsonPath];
    
    NSManagedObjectContext *moc = [self managedObjectContext];
        
    NSArray *stops = [NSArray arrayWithObjects:@"West Portal Station",@"Forest Hill Station",@"Castro Station",@"Church Station",@"Van Ness Station",@"Civic Center Station",@"Powell Station",@"Montgomery Station",@"Embarcadero Station",@"Folsom & Embarcadero",@"Brannan & Embarcadero",@"2nd & King / Ballpark",@"4th & King / Caltrain", nil];
    
    for (int i = 0; i < [[jsonData objectForKey:@"StopList"] count]; i++) {
        NSDictionary *stopDict = [[jsonData objectForKey:@"StopList"] objectAtIndex:i];
        
        Stop *stop = [NSEntityDescription insertNewObjectForEntityForName:@"Stop" inManagedObjectContext:moc];
//        [stop setValue:[NSNumber numberWithBool:YES] forKey:@"subway"];
        [stop setValue:[stopDict objectForKey:@"Title"] forKey:@"name"];
//        [stop setValue:[NSNumber numberWithInt:i] forKey:@"subwayOrder"];
//        [stop setValue:[NSNumber numberWithInt:i] forKey:@"inboundId"];

    }
    
    for (int i = 0; i < [[jsonData objectForKey:@"LineList"] count]; i++) {
        NSDictionary *lineDict = [[jsonData objectForKey:@"LineList"] objectAtIndex:i];
        
        Line *line = [NSEntityDescription insertNewObjectForEntityForName:@"Line" inManagedObjectContext:moc];
        [line setValue:[lineDict objectForKey:@"Title"] forKey:@"name"];
    }
    
    NSError *err;
    if (![moc save:&err]) {
        NSLog(@"Whoops, error saving demo data: %@",[err localizedDescription]);
    }
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

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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
