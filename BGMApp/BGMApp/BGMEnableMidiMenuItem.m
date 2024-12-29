//
//  BGMEnableMidiMenuItem.m
//  Background Music
//
//  Created by Borey UK on 29/12/2024.
//  Copyright © 2024 Background Music contributors. All rights reserved.
//

#import "BGMEnableMidiMenuItem.h"
#import "CADebugMacros.h"



@implementation BGMEnableMidiMenuItem {
    NSMenuItem* _menuItem;
    BGMAudioDeviceManager* _audioDevices;
    BGMAppVolumesController* _volumeController;
}


void midiReadProc(const MIDIPacketList *pktlist, void * __nullable readProcRefCon, void * __nullable srcConnRefCon) {
    if (readProcRefCon == NULL || srcConnRefCon == NULL) {
        return;
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
        // menuItem.action = @selector(toggleEnableMIDI);
        _audioDevices = audioDevices;
        _volumeController = audioController;
    }
    [self connectToMIDI];
    return self;
}

static MIDIClientRef client;
static MIDIPortRef inport;

- (void) connectToMIDI {
    CFStringRef clientName = CFStringCreateWithCString(NULL, "MIDI Client", kCFStringEncodingUTF8);
    MIDIClientCreate(clientName, NULL, NULL, &client);
    CFStringRef portName = CFStringCreateWithCString(NULL, "MIDI Client", kCFStringEncodingASCII);
    MIDIInputPortCreate(client, portName, midiReadProc, (__bridge void * _Nullable)(self), &inport);
    
    MIDIEndpointRef source = MIDIGetSource(0);
    MIDIPortConnectSource(inport, source, &source);
    
    CFRelease(clientName);
    CFRelease(portName);
}

- (void) midiPacketCallback:(const MIDIPacketList *)packetList {
    MIDIPacket packet = *packetList->packet;
    
    unsigned char byte1 = packet.data[0];
    if(byte1 >= 0x80 && byte1 <= 0xEF){
        unsigned char messageType = (byte1 & 0xF0) >> 4;
        // unsigned char messageChannel = byte1 & 0x0F;
        // printf("midi: got message %x on channel %x\n", messageType, messageChannel);
        if(messageType == 0xB) {
            unsigned char controller = packet.data[1] & 0x7F;
            unsigned char value = packet.data[2] & 0x7F;
            // printf("midi: got ControlChange message, controller %d, value %d\n", controller, value);
            int normalizedValue = (int)((50.0/127.0) * value); // values from midi controller are between 0;127
            // printf("midi: normalizedVolume %d\n", normalizedValue);
            
            NSArray<NSRunningApplication*>* apps = [self->_volumeController getRunningApplications];
            
            if(controller == 36 || controller == 37) { // currently hardcoded for my akai lpd8
                for (NSRunningApplication* app in apps) {
                    // DebugMsg("midi: app: %s\n", [app.description cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                    if(([app.bundleIdentifier isEqualToString:@"com.spotify.client"] && controller == 36) ||
                       (([app.bundleIdentifier isEqualToString:@"org.mozilla.firefox"] || [app.bundleIdentifier isEqualToString:@"org.mozilla.plugincontainer"]) && controller == 37)){
                        // printf("midi: okidoki (controller %d, target bundle %s)\n", controller, [app.description cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                        [self->_volumeController setVolume: normalizedValue forAppWithProcessID:app.processIdentifier bundleID:app.bundleIdentifier];
                        break;
                    }
                }
            }
        }
    }
}

- (void) dealloc {
    // TODO: clean up MIDI connections
    printf("cleaning up midi menu item...");
    MIDIPortDispose(inport);
    MIDIClientDispose(client);
}


@end
