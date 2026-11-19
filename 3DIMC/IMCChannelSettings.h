//
//  IMCChannelSettings.h
//  IMCReader
//
//  Created by Raul Catena on 1/21/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IMCChannelSettings;
@protocol ChannelConfCell <NSObject>

-(void)madeChannelConfChanges;
-(NSInteger)numberOfChannels;
-(NSInteger)typeOfColoring;
-(void)changed:(NSInteger)oldChannel for:(NSInteger)newChannel;

@optional
//Maximum raw value (counts) of a channel, used to convert the Max/Offset sliders to counts. 0 if unknown.
-(float)maxValueForChannel:(NSInteger)index;

@end

@interface IMCChannelSettings : NSTableCellView

@property (nonatomic, weak) IBOutlet NSTextField * label;
@property (nonatomic, weak) IBOutlet NSSlider *maxOffset;
@property (nonatomic, weak) IBOutlet NSSlider *offset;
@property (nonatomic, weak) IBOutlet NSSlider *multiplier;
@property (nonatomic, weak) IBOutlet NSSlider *pixelFilter;
@property (nonatomic, weak) IBOutlet NSPopUpButton *filter;
@property (nonatomic, weak) IBOutlet NSPopUpButton *selectChannel;
@property (nonatomic, weak) IBOutlet NSColorWell *color;
@property (nonatomic, weak) IBOutlet NSButton *showOrNot;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *transformData;
@property (nonatomic, weak) IBOutlet NSView *background;
//Text fields next to the Max and Offset sliders to type the values in counts (created in code)
@property (nonatomic, strong) NSTextField *maxCountField;
@property (nonatomic, strong) NSTextField *offsetCountField;
@property (nonatomic, strong) NSTextField *multiplierField;
@property (nonatomic, strong) NSTextField *pixelFilterField;
//Help button with a popover explaining the controls (created in code)
@property (nonatomic, strong) NSButton *helpButton;
@property (nonatomic, strong) NSPopover *helpPopover;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) NSInteger localIndex;

@property (nonatomic, strong) NSMutableDictionary *settingsDictionary;

@property (nonatomic, weak) NSArray *channels;

@property (nonatomic, assign) id<ChannelConfCell>delegate;

-(IBAction)selectedChannel:(id)sender;
-(IBAction)changedChannel:(NSPopUpButton *)sender;
-(void)setTag:(NSInteger)atag;

@end
