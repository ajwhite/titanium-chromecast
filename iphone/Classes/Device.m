//
//  Device.m
//  titanium-chromecast
//
//  Created by Atticus White on 12/20/14.
//
//

#import "Device.h"
@implementation Device

NSString * const PROXY_KEY_VIDEO = @"video";
NSString * const PROXY_KEY_METADATA = @"metadata";
NSString * const PROXY_KEY_TITLE = @"title";
NSString * const PROXY_KEY_SUBTITLE = @"subTitle";
NSString * const PROXY_KEY_IMAGE = @"image";
NSString * const PROXY_KEY_IMAGE_SRC = @"src";
NSString * const PROXY_KEY_IMAGE_WIDTH = @"width";
NSString * const PROXY_KEY_IMAGE_HEIGHT = @"height";
NSString * const PROXY_KEY_VIDEO_SRC = @"src";
NSString * const PROXY_KEY_CONTENT_TYPE = @"contentType";

-(instancetype)initWithDevice:(GCKDevice*)device initWithDeviceManager:(id<DeviceManagerDelegate>)deviceManager
{
    if (self = [super init]) {
        self.device = device;
        self.deviceManager = deviceManager;
    }
    return self;
}

-(id)friendlyName
{
    return self.device.friendlyName;
}

-(id)ipAddress
{
    return self.device.ipAddress;
}

-(id)deviceID
{
    return self.device.deviceID;
}

-(NSDictionary*)toJSON:(id)args
{
    NSLog(@"Going to json");
    NSDictionary *json = [NSDictionary dictionaryWithObjectsAndKeys:
                          self.device.friendlyName, @"friendlyName",
                          self.device.ipAddress, @"ipAddress",
                          self.device.deviceID, @"deviceID",
                          self.device.manufacturer, @"manufacturer",
                          self.device.modelName, @"modelName",
                          self.device.statusText, @"statusText",
                          nil];
    return json;
}


-(void)connect:(id)args
{
    ENSURE_UI_THREAD(connect, args);
    NSUInteger argC = [args count];
    
    if (argC > 0) {
        ENSURE_TYPE([args objectAtIndex:0], KrollCallback);
        self.onDeviceSuccessfullyConnectedCallback = [args objectAtIndex: 0];
    }
    if (argC > 1) {
        ENSURE_TYPE([args objectAtIndex: 1], KrollCallback);
        self.onDeviceFailedToConnectCallback = [args objectAtIndex: 1];
    }
    [self.deviceManager connect:self];
}

-(void)launchApplication:(id)args
{
    NSUInteger argC = [args count];
    if (argC > 0) {
        ENSURE_TYPE([args objectAtIndex:0], KrollCallback);
        self.onApplicationSuccesfullyLaunchedCallback = [args objectAtIndex: 0];
    }
    if (argC > 1) {
        ENSURE_TYPE([args objectAtIndex:1], KrollCallback);
        self.onApplicationFailedToLaunchCallback = [args objectAtIndex: 1];
    }
    [self.deviceManager launchApplication];
}

-(void)castVideo:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    [self.deviceManager removeChannel];
    
    NSDictionary *videoDict = args[PROXY_KEY_VIDEO];
    NSDictionary *metaDataDict = args[PROXY_KEY_METADATA];
    NSDictionary *metaDataImage;
    GCKMediaMetadata *metadata;
    
    if (metaDataDict) {
        metaDataImage = [metaDataDict objectForKey: PROXY_KEY_IMAGE];
        
        metadata = [[GCKMediaMetadata alloc] init];
        if ([metaDataDict objectForKey:PROXY_KEY_TITLE]) {
            [metadata setString:metaDataDict[PROXY_KEY_TITLE] forKey: kGCKMetadataKeyTitle];
        }
        if ([metaDataDict objectForKey: PROXY_KEY_SUBTITLE]) {
            [metadata setString:metaDataDict[PROXY_KEY_SUBTITLE] forKey: kGCKMetadataKeySubtitle];
        }
        
        if (metaDataImage) {
            [metadata addImage: [[GCKImage alloc] initWithURL: [[NSURL alloc] initWithString: [metaDataImage objectForKey: PROXY_KEY_IMAGE_SRC]]
                                                        width: [metaDataImage objectForKey: PROXY_KEY_IMAGE_WIDTH]
                                                       height: [metaDataImage objectForKey: PROXY_KEY_IMAGE_HEIGHT]
                                 ]];
        }
    }

    GCKMediaInformation *mediaInformation =
    [[GCKMediaInformation alloc] initWithContentID: [videoDict objectForKey: PROXY_KEY_VIDEO_SRC]
                                        streamType:GCKMediaStreamTypeNone
                                       contentType: [videoDict objectForKey: PROXY_KEY_CONTENT_TYPE]
                                          metadata:metadata
                                    streamDuration:0
                                        customData:nil];
    [self.deviceManager loadMedia:mediaInformation];
}

-(void)castImage:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    [self.deviceManager removeChannel];
    
    GCKMediaInformation *mediaInformation = [[GCKMediaInformation alloc]
                                             initWithContentID: [args objectForKey:PROXY_KEY_IMAGE_SRC]
                                             streamType: GCKMediaStreamTypeNone
                                             contentType:[args objectForKey: PROXY_KEY_CONTENT_TYPE]
                                             metadata: nil
                                             streamDuration: 0
                                             customData: nil];
    
    [self.deviceManager loadMedia: mediaInformation];
}

-(void)addChannel:(id)channelNamespace
{
    ENSURE_SINGLE_ARG(channelNamespace, NSString);
    [self.deviceManager addChannel:channelNamespace];
}

-(void)removeChannel:(id)args
{
    [self.deviceManager removeChannel];
}

-(void)sendMessage:(id)message
{
    ENSURE_SINGLE_ARG(message, NSString);
    [self.deviceManager sendMessage:message];
}

-(void)sendJsonMessage:(id)message
{
    id jsonDict = [message objectAtIndex: 0];;
    NSString *jsonString = [GCKJSONUtils writeJSON:jsonDict];
    [self.deviceManager sendMessage:jsonString];
}

-(void)onMessageReceived:(NSString*)message
{
    NSDictionary *messageDictionary = [NSDictionary dictionaryWithObjectsAndKeys: message, @"message", nil];
    [self fireEvent:@"messageReceived" withObject:messageDictionary];
}

-(BOOL)isConnected:(id)args
{
    return [self.deviceManager isDeviceEqualToConnectedDevice:self];
}

-(BOOL)isConnectedToApp:(id)args
{
    return [self.deviceManager isDeviceEqualToConnectedDevice:self] &&
    [self.deviceManager isConnectedToApp];
}


#pragma mark Callbacks
-(void)onDeviceSuccessfullyConnected
{
    NSLog(@"Device has been pinged of the succesful connection!");
    if (self.onDeviceSuccessfullyConnectedCallback != nil) {
        [self.onDeviceSuccessfullyConnectedCallback call:@[] thisObject: self];
    }
}

-(void)onDeviceFailedToConnect:(NSError*)error
{
    NSLog(@"Error connecting to device");
    if (self.onDeviceFailedToConnectCallback != nil) {
        [self.onDeviceFailedToConnectCallback call:@[[error localizedDescription]] thisObject:self];
    }
}

-(void)onApplicationSuccessfullyLaunched:(NSString*)sessionID launchedApplication:(BOOL)launchedApplication
{
    if (self.onApplicationSuccesfullyLaunchedCallback != nil) {
        [self.onApplicationSuccesfullyLaunchedCallback call:@[sessionID] thisObject:self];
    }
}

-(void)onApplicationFailedToLaunch:(NSError*)error
{
    if (self.onApplicationFailedToLaunchCallback != nil) {
        [self.onApplicationFailedToLaunchCallback call:@[[error localizedDescription]] thisObject:self];
    }
}


@end