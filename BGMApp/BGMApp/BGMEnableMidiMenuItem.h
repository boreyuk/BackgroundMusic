//
//  BGMEnableMidiMenuItem.h
//  Background Music
//
//  Created by Borey UK on 29/12/2024.
//  Copyright © 2024 Background Music contributors. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreMIDI/CoreMIDI.h>
#import "BGMAudioDeviceManager.h"
#import "BGMAppVolumesController.h"


#pragma clang assume_nonnull begin

void connectToMIDI(void);

void midiReadProc(const MIDIPacketList *pktlist, void * __nullable readProcRefCon, void * __nullable srcConnRefCon);

@interface BGMEnableMidiMenuItem : NSObject

- (instancetype) initWithMenuItem:(NSMenuItem*)menuItem
                     audioDevices:(BGMAudioDeviceManager*)audioDevices
                     volumesController:(BGMAppVolumesController*)audioController;

- (void) connectToMIDI;

// - (void) midiPacketCallback:(const MIDIPacketList*)pktlist refCon:(void * __nullable)readProcRefCon srcRefCon:(void * __nullable)srcConnRefCon;

- (void) midiPacketCallback:(const MIDIPacketList *)packetList;

@end

#pragma clang assume_nonnull end
