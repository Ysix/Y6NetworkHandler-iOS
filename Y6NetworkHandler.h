//
//  Y6NetworkHandler.h
//
//  Created by Ysix on 23/07/13.
//

#import <Foundation/Foundation.h>

// Needs :  systemConfiguration Framework
//          AFNetworking 2.0
//          Reachability Class (from Apple sample)



// flag no ARC : -fno-objc-arc

#define ERROR_CODE_NO_INTERNET      -1
#define ERROR_CODE_HOST_UNREACHABLE -2
#define ERROR_CODE_REQUEST_FAILED   -3

@class Reachability;

@interface Y6NetworkHandler : NSObject
{
    NSString    *serverAddress;
    Reachability    *internetReachability;
    Reachability    *hostReachability;
    
    BOOL            internetReachable;
    BOOL            hostReachable;
    
    BOOL            ready;
    NSMutableArray  *stack;
}

- (id)initWithServerAddress:(NSString *)url;
- (id)initWithServerIp:(NSString *)serverIp;

- (int)isConnectedToInternet;

- (void)getJsonParsedFrom:(NSString *)serviceAddress withPostParameters:(NSDictionary *)postParamDict andGetParameters:(NSDictionary *)getParamDict completion:(void ( ^ ) ( id JSON ))completionBlock;

@end
