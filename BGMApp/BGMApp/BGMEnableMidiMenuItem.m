//
//  BGMEnableMidiMenuItem.m
//  Background Music
//
//  Created by Borey UK on 29/12/2024.
//  Copyright © 2024 Background Music contributors. All rights reserved.
//

#import "BGMEnableMidiMenuItem.h"


@implementation BGMEnableMidiMenuItem {
    NSMenuItem* _menuItem;
    BGMAudioDeviceManager* _audioDevices;
    BGMAppVolumesController* _volumeController;
}


void midiReadProc(const MIDIPacketList *pktlist, void * __nullable readProcRefCon, void * __nullable srcConnRefCon) {
    if (readProcRefCon == NULL) {
        printf("mdr\n");
    }
    
    if (srcConnRefCon == NULL) {
        printf("mdr 2\n");
    }
    
    BGMEnableMidiMenuItem *self = (__bridge BGMEnableMidiMenuItem*)(readProcRefCon);
    [self midiPacketCallback:pktlist];
}

- (instancetype) initWithMenuItem:(nonnull NSMenuItem *)menuItem
                     audioDevices:(nonnull BGMAudioDeviceManager *)audioDevices
                volumesController:(nonnull BGMAppVolumesController *)audioController{
    if ((self = [super init])) {
        _menuItem = menuItem;
        _menuItem.state = NSControlStateValueOn;
        menuItem.target = self;
        menuItem.action = @selector(toggleEnableMIDI);
        _audioDevices = audioDevices;
        _volumeController = audioController;
    }
    [self connectToMIDI];
    return self;
}

- (void) connectToMIDI {
    MIDIClientRef client;
    CFStringRef clientName = CFStringCreateWithCString(NULL, "hello world", kCFStringEncodingUTF8);
    OSStatus res = MIDIClientCreate(clientName, NULL, NULL, &client);
    
    printf("opened midi client: %d\n", res);
    
    MIDIPortRef inport;
    CFStringRef portName = CFStringCreateWithCString(NULL, "LPD8 mk2", kCFStringEncodingASCII);
    
    res = MIDIInputPortCreate(client, portName, midiReadProc, (__bridge void * _Nullable)(self), &inport);
    printf("opened midi port: %d\n", res);
    
    MIDIEndpointRef source = MIDIGetSource(0);
    MIDIPortConnectSource(inport, source, &source);
    
    /*
    MIDIPortDispose(inport);
    MIDIClientDispose(client);
    CFRelease(clientName);
    CFRelease(portName);
    */
}

- (void) midiPacketCallback:(const MIDIPacketList *)packetList {
    MIDIPacket packet = *packetList->packet;
    
    unsigned char byte1 = packet.data[0];
    if(byte1 >= 0x80 && byte1 <= 0xEF){
        printf("midi: getting Channel Type..\n");
        unsigned char messageType = (byte1 & 0xF0) >> 4;
        unsigned char messageChannel = byte1 & 0x0F;
        printf("midi: got message %x on channel %x\n", messageType, messageChannel);
        if(messageType == 0xB) {
            unsigned char byte2 = packet.data[1];
            unsigned char byte3 = packet.data[2];
            unsigned char controller = byte2 & 0x7F;
            unsigned char value = byte3 & 0x7F;
            printf("midi: got ControlChange message, controller %d, value %d\n", controller, value);
            int normalizedValue = (int)((50.0/127.0) * value);
            printf("normalizedVolume %d", normalizedValue);
            [self->_volumeController setVolume:normalizedValue forAppWithProcessID:18087 bundleID:@"com.spotify.client"];
        }
    }
}

- (void) midiPacketCallback:(const MIDIPacketList*)pktlist refCon:(void * __nullable)readProcRefCon srcRefCon:(void * __nullable)srcConnRefCon {
    if (readProcRefCon == NULL) {
        printf("mdr\n");
    }
    
    if (srcConnRefCon == NULL) {
        printf("mdr 2\n");
    }
    MIDIPacketList packetList = *pktlist;
    MIDIPacket packet = *packetList.packet;
    
    unsigned char byte1 = packet.data[0];
    if(byte1 >= 0x80 && byte1 <= 0xEF){
        printf("midi: getting Channel Type..\n");
        unsigned char messageType = (byte1 & 0xF0) >> 4;
        unsigned char messageChannel = byte1 & 0x0F;
        printf("midi: got message %x on channel %x\n", messageType, messageChannel);
        if(messageType == 0xB) {
            unsigned char byte2 = packet.data[1];
            unsigned char byte3 = packet.data[2];
            unsigned char controller = byte2 & 0x7F;
            unsigned char value = byte3 & 0x7F;
            printf("midi: got ControlChange message, controller %d, value %d\n", controller, value);
        }
    }
    
    
}


- (void) dealloc {
    
}

- (void) toggleEnableMIDI {
    /*
    if (_menuItem.state == NSControlStateValueOff) {
        _menuItem.state = NSControlStateValueOn;
        return;
    }
    _menuItem.state = NSControlStateValueOff;
    */
    /*
    MIDIPortRef outport;
    MIDIOutputPortCreate(client, (CFStringRef) "LPD 8 mk2", &outport);
    */
    
}


@end
