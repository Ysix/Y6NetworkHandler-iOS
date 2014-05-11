//
//  Y6NetworkHandler.m
//
//  Created by Ysix on 23/07/13.
//

#import "Y6NetworkHandler.h"
#import "AFNetworking.h"
#import "Reachability.h"

@implementation Y6NetworkHandler

- (id)initWithServerAddress:(NSString *)url
{
    if (self = [self init])
    {
        serverAddress = url;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        
        internetReachability = [Reachability reachabilityForInternetConnection];
        hostReachability = [Reachability reachabilityWithHostName:serverAddress];
        [internetReachability startNotifier];
        [hostReachability startNotifier];

        ready = NO;
        
        stack = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)reachabilityChanged:(NSNotification *)note
{
    NSLog(@"Reachability Changed");
    
    Reachability* curReach = [note object];
    
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);

    if (curReach == internetReachability)
    {
        internetReachable = ([curReach currentReachabilityStatus] == NotReachable ? NO : YES);
    }
    else if (curReach == hostReachability)
    {
        hostReachable = ([curReach currentReachabilityStatus] == NotReachable ? NO : YES);
    }
    
    if (!ready)
    {
        ready = YES;
        
        for (NSDictionary *dict in stack)
        {
            [self getJsonParsedFrom:[dict objectForKey:@"serviceAddress"] withPostParameters:[dict objectForKey:@"postParamDict"] andGetParameters:[dict objectForKey:@"getParamDict"] completion:[dict objectForKey:@"completionBlock"]];
        }
    }
}

- (int)isConnectedToInternet
{
    if (internetReachable || hostReachable)
    {
        if (hostReachable)
        {
            return 1;
        }
        return ERROR_CODE_HOST_UNREACHABLE;
    }
    return ERROR_CODE_NO_INTERNET;
}

- (void)getJsonParsedFrom:(NSString *)serviceAddress withPostParameters:(NSDictionary *)postParamDict andGetParameters:(NSDictionary *)getParamDict completion:(void ( ^ ) ( id JSON ))completionBlock
{
    if (!ready)
    {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        if (serviceAddress)
            [dict setObject:serviceAddress forKey:@"serviceAddress"];
        if (postParamDict)
            [dict setObject:postParamDict forKey:@"postParamDict"];
        if (getParamDict)
            [dict setObject:getParamDict forKey:@"getParamDict"];
        if (completionBlock)
            [dict setObject:completionBlock forKey:@"completionBlock"];
        
        [stack addObject:dict];
        
        return;
    }
    
    int connectionStatus = [self isConnectedToInternet];
    
    if (connectionStatus < 1)
    {
        completionBlock(@{@"success" : @"0", @"error" : @{@"code" : [NSString stringWithFormat:@"%d", connectionStatus], @"message" : (connectionStatus == ERROR_CODE_HOST_UNREACHABLE ? @"The host is unreachable, please try again later." : @"You don't have an internet connection, or it's too slow.")}});
        return;
    }
    
    if (postParamDict)
    {
        [[AFHTTPSessionManager manager] POST:serviceAddress parameters:postParamDict success:^(NSURLSessionDataTask *task, id responseObject) {
            completionBlock(responseObject);

        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            
            NSLog(@"error network handler : %@", [error localizedDescription]);

            completionBlock(@{@"success" : @"0", @"error" : @{@"code" : [NSString stringWithFormat:@"%d", ERROR_CODE_REQUEST_FAILED], @"message" : @"An error occurred, please try again."}});
        }];
    }
    else
    {
        [[AFHTTPSessionManager manager] GET:serviceAddress parameters:getParamDict success:^(NSURLSessionDataTask *task, id responseObject) {
            completionBlock(responseObject);
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            
            NSLog(@"error network handler : %@", [error localizedDescription]);
            
            completionBlock(@{@"success" : @"0", @"error" : @{@"code" : [NSString stringWithFormat:@"%d", ERROR_CODE_REQUEST_FAILED], @"message" : @"An error occurred, please try again."}});
        }];
    }
    
}

@end
