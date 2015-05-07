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
			[self jsonParsedBy:[[dict objectForKey:@"methodNumber"] intValue] from:[dict objectForKey:@"serviceAddress"] withParameters:[dict objectForKey:@"paramDict"] completion:[dict objectForKey:@"completionBlock"]];
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
	if (postParamDict)
	{
		[self jsonParsedBy:POST from:serviceAddress withParameters:postParamDict completion:completionBlock];
	}
	else
	{
		[self jsonParsedBy:GET from:serviceAddress withParameters:postParamDict completion:completionBlock];
	}
}

- (void)jsonParsedBy:(HTTPMethod)method from:(NSString *)serviceAddress withParameters:(NSDictionary *)paramDict completion:(void (^)(id))completionBlock
{
	if (!ready)
	{
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		if (serviceAddress)
			[dict setObject:serviceAddress forKey:@"serviceAddress"];
		if (paramDict)
			[dict setObject:paramDict forKey:@"paramDict"];
		if (method)
			[dict setObject:[NSNumber numberWithInt:method] forKey:@"methodNumber"];
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

	void (^successBlock)(NSURLSessionDataTask *, id ) = ^void(NSURLSessionDataTask *task, id responseObject)
	{
#if DEBUG
		NSLog(@"got : %@", responseObject);
#endif
		completionBlock(responseObject);
	};

	void (^failureBlock)(NSURLSessionDataTask *, NSError *) = ^void(NSURLSessionDataTask *task, NSError *error) {
		NSLog(@"error network handler : %@", [error localizedDescription]);
		completionBlock(@{@"success" : @"0", @"error" : @{@"code" : [NSString stringWithFormat:@"%d", ERROR_CODE_REQUEST_FAILED], @"message" : @"An error occurred, please try again."}});
	};

#if DEBUG

	NSLog(@"make %d on %@ with parameters %@", method, serviceAddress, paramDict);

#endif

	switch (method)
	{
		case GET:
		{
			[[AFHTTPSessionManager manager] GET:serviceAddress parameters:paramDict success:successBlock failure:failureBlock];
			break;
		}
		case POST:
		{
			[[AFHTTPSessionManager manager] POST:serviceAddress parameters:paramDict success:successBlock failure:failureBlock];
			break;
		}
		case PUT:
		{
			[[AFHTTPSessionManager manager] PUT:serviceAddress parameters:paramDict success:successBlock failure:failureBlock];
			break;
		}
		case DELETE:
		{
			[[AFHTTPSessionManager manager] DELETE:serviceAddress parameters:paramDict success:successBlock failure:failureBlock];
			break;
		}
		default:
			break;
	}
}


@end
