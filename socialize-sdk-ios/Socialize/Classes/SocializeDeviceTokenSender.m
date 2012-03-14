//
//  SocializeDeviceTokenSender.m
//  SocializeSDK
//
//  Created by Nathaniel Griswold on 2/14/12.
//  Copyright (c) 2012 Socialize, Inc. All rights reserved.
//

#import "SocializeDeviceTokenSender.h"
#import "SocializeCommonDefinitions.h"
#import "_Socialize.h"
#import "NSTimer+BlocksKit.h"

@interface SocializeDeviceTokenSender ()
- (void)startTimer;
- (void)sendDeviceTokenIfNecessary;
- (void)resendDeviceToken;
@property (nonatomic, assign) BOOL tokenOnServer;
@end

static SocializeDeviceTokenSender *sharedDeviceTokenSender;
static NSTimeInterval TimerCheckTimeInterval = 30.0;

@implementation SocializeDeviceTokenSender
@synthesize socialize = socialize_;
@synthesize timer = timer_;
@synthesize tokenOnServer = tokenOnServer_;

+ (void)load {
    (void)[self sharedDeviceTokenSender];
}

+ (SocializeDeviceTokenSender*)sharedDeviceTokenSender {
    if (sharedDeviceTokenSender == nil) {
        sharedDeviceTokenSender = [[SocializeDeviceTokenSender alloc] init];
    }
    return sharedDeviceTokenSender;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [socialize_ setDelegate:nil];
    self.socialize = nil;
    [timer_ invalidate];
    self.timer = nil;
    
    [super dealloc];
}

- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userChanged:) name:SocializeAuthenticatedUserDidChangeNotification object:nil];
    }
    return self;
}

- (Socialize*)socialize {
    if (socialize_ == nil) {
        socialize_ = [[Socialize alloc] initWithDelegate:self];
    }
    
    return socialize_;
}

-(NSString*)stringForToken:(NSData*)token {
    NSString *deviceTokenString = [[[[token description]
                                     stringByReplacingOccurrencesOfString: @"<" withString: @""]
                                    stringByReplacingOccurrencesOfString: @">" withString: @""]
                                   stringByReplacingOccurrencesOfString: @" " withString: @""];
    return deviceTokenString;
}

- (void)registerDeviceToken:(NSData*)deviceToken {
    NSString *deviceTokenString = [self stringForToken:deviceToken];
    NSAssert([deviceTokenString length] > 0, @"Bad token");
    [[NSUserDefaults standardUserDefaults] setObject:deviceTokenString forKey:kSocializeDeviceTokenKey];
    [self resendDeviceToken];
}

- (void)sendDeviceTokenIfNecessary {
    NSString *existingToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSocializeDeviceTokenKey];
    if ([existingToken length] > 0 && !self.tokenOnServer) {
        [self.socialize _registerDeviceTokenString:existingToken];
    }
}

- (void)resendDeviceToken {
    self.tokenOnServer = NO;
    [self sendDeviceTokenIfNecessary];
}

- (void)timerCheck {
    if (!self.tokenOnServer) {
        // Token still does not exist on server
        [self sendDeviceTokenIfNecessary];
    } else {
        
        // Token is on the server, so the timer is no longer necessary
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)startTimer {
    __block id weakSelf = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:TimerCheckTimeInterval block:^(NSTimeInterval time) {
        [weakSelf timerCheck];
    } repeats:YES];
}

- (void)startTimerIfNecessary {
    if (self.timer != nil)
        return;
    
    if (self.tokenOnServer)
        return;
    
    [self startTimer];
}

- (void)userChanged:(id<SocializeUser>)newUser {
    [self resendDeviceToken];
}

- (BOOL)tokenAvailable {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kSocializeDeviceTokenKey];
    return [token length] > 0;
}

- (void)service:(SocializeService *)service didFail:(NSError *)error {
    NSLog(@"Socialize: device token registration failed (%@). Retrying in %f seconds", [error localizedDescription], TimerCheckTimeInterval);

    [self startTimerIfNecessary];
}

- (void)service:(SocializeService *)service didCreate:(id<SocializeObject>)object {
    id<SocializeDeviceToken> token = (id<SocializeDeviceToken>)object;
    NSString *serverToken = [token device_token];
    NSString *storedToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSocializeDeviceTokenKey];
    
    if ([serverToken length] > 0 && [[serverToken lowercaseString] isEqualToString:[storedToken lowercaseString]]) {
        NSLog(@"Socialize: device token %@ successfully registered with server", serverToken);
        self.tokenOnServer = YES;
    } else {
        
        NSLog(@"Socialize: token registration problem: server token (%@) did not match stored token (%@)", serverToken, storedToken);

        // Something went wrong
        [self startTimerIfNecessary];
    }
}

@end
