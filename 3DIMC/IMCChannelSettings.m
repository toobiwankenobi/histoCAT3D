//
//  IMCChannelSettings.m
//  IMCReader
//
//  Created by Raul Catena on 1/21/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCChannelSettings.h"
#import "IMCImageGenerator.h"

@implementation IMCChannelSettings

-(void)awakeFromNib{
    [super awakeFromNib];
    if(self.maxCountField)
        return;
    self.maxCountField = [self countFieldNextToSlider:self.maxOffset
                                              toolTip:@"Max in counts (values at or above are shown at full intensity)"];
    self.offsetCountField = [self countFieldNextToSlider:self.offset
                                                 toolTip:@"Offset in counts (values below are shown black)"];
    self.multiplierField = [self countFieldNextToSlider:self.multiplier
                                                toolTip:@"Multiplier (brightness gain)"];
}

#pragma mark count input fields

-(NSTextField *)countFieldNextToSlider:(NSSlider *)slider toolTip:(NSString *)toolTip{
    if(!slider)
        return nil;
    const CGFloat fieldWidth = 54.0f, gap = 4.0f, fieldHeight = 18.0f;

    NSRect sliderFrame = slider.frame;
    sliderFrame.size.width -= fieldWidth + gap;
    slider.frame = sliderFrame;

    NSTextField *field = [[NSTextField alloc]initWithFrame:NSMakeRect(NSMaxX(sliderFrame) + gap,
                                                                      NSMidY(sliderFrame) - fieldHeight / 2,
                                                                      fieldWidth, fieldHeight)];
    field.font = [NSFont systemFontOfSize:10.0f];
    field.alignment = NSTextAlignmentRight;
    field.autoresizingMask = slider.autoresizingMask;
    field.placeholderString = @"–";
    field.toolTip = toolTip;

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator = NO;
    formatter.maximumFractionDigits = 2;//out-of-range values are clamped in enteredCount: instead of rejected
    field.formatter = formatter;

    field.target = self;
    field.action = @selector(enteredCount:);
    [field.cell setSendsActionOnEndEditing:YES];//apply on Return and when leaving the field

    [slider.superview addSubview:field];
    return field;
}

-(float)channelMax{
    if([self.delegate respondsToSelector:@selector(maxValueForChannel:)])
        return [self.delegate maxValueForChannel:self.index];
    return .0f;
}

//Counts only map linearly onto the sliders for untransformed data (UT)
-(BOOL)countsAreLinear{
    return self.transformData.selectedSegment == 0;
}

-(void)updateCountFields{
    self.multiplierField.floatValue = self.multiplier.floatValue;//always available

    float max = [self channelMax];
    BOOL usable = max > .0f && [self countsAreLinear];
    self.maxCountField.enabled = usable;
    self.offsetCountField.enabled = usable;
    if(!usable){
        self.maxCountField.stringValue = @"";
        self.offsetCountField.stringValue = @"";
        return;
    }
    float maxCounts = max * self.maxOffset.floatValue;
    float mult = MAX(self.multiplier.floatValue, 1e-6f);
    self.maxCountField.floatValue = maxCounts;
    //Offset is a fraction of the displayed range, which is max / mult
    self.offsetCountField.floatValue = self.offset.floatValue * maxCounts / mult;
}

-(void)enteredCount:(NSTextField *)sender{
    if(sender == self.multiplierField){
        self.multiplier.floatValue = MIN(self.multiplier.maxValue, MAX(self.multiplier.minValue, sender.floatValue));
        [self selectedChannel:sender];
        return;
    }
    float max = [self channelMax];
    if(max <= .0f || ![self countsAreLinear]){
        [self updateCountFields];
        return;
    }
    float value = MAX(.0f, sender.floatValue);
    if(sender == self.maxCountField){
        //Never 0: the image generator divides by it
        self.maxOffset.floatValue = MIN(1.0f, MAX(value / max, 0.001f));
    }else if(sender == self.offsetCountField){
        float maxCounts = max * self.maxOffset.floatValue;
        float mult = MAX(self.multiplier.floatValue, 1e-6f);
        self.offset.floatValue = maxCounts > .0f ? MIN(1.0f, value * mult / maxCounts) : .0f;
    }
    [self selectedChannel:sender];
}

-(void)setChannels:(NSArray *)channels{
    _channels = channels;
    if(self.selectChannel.itemArray.count != channels.count){
        for (NSString *str in _channels) {//TODO refactor this
            [self.selectChannel addItemWithTitle:@"blah"];
            [[self.selectChannel lastItem]setTitle:str];
        }
    }
}

-(void)setSettingsDictionary:(NSMutableDictionary *)settingsDictionary{
    _settingsDictionary = settingsDictionary;
    self.maxOffset.floatValue = [[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_MAXOFFSET]floatValue];
    self.offset.floatValue = [[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_OFFSET]floatValue];
    self.multiplier.floatValue = [[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_MULTIPLIER]floatValue];
    self.pixelFilter.floatValue = [[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_SPF]floatValue];
    [self.transformData setSelectedSegment:MAX(0,MIN(2,[[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_TRANSFORM]integerValue]))];
    if([self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_COLOR])
        self.color.color = [NSColor colorFromHexString:[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_COLOR]];
    
    self.color.enabled = ([self.delegate typeOfColoring] == 4);
}

-(void)selectedChannel:(id)sender{
    [self.settingsDictionary setValue:[NSNumber numberWithFloat:self.maxOffset.floatValue] forKey:JSON_DICT_CHANNEL_SETTINGS_MAXOFFSET];
    [self.settingsDictionary setValue:[NSNumber numberWithFloat:self.offset.floatValue] forKey:JSON_DICT_CHANNEL_SETTINGS_OFFSET];
    [self.settingsDictionary setValue:[NSNumber numberWithFloat:self.multiplier.floatValue] forKey:JSON_DICT_CHANNEL_SETTINGS_MULTIPLIER];
    [self.settingsDictionary setValue:[NSNumber numberWithFloat:self.pixelFilter.floatValue] forKey:JSON_DICT_CHANNEL_SETTINGS_SPF];
    [self.settingsDictionary setValue:[NSNumber numberWithInteger:self.transformData.selectedSegment] forKey:JSON_DICT_CHANNEL_SETTINGS_TRANSFORM];
    [self.settingsDictionary setValue:[self.color.color hexEncoding] forKey:JSON_DICT_CHANNEL_SETTINGS_COLOR];
    
    if([sender isMemberOfClass:[NSColorWell class]])
        [sender resignFirstResponder];
    
    [self.delegate madeChannelConfChanges];
    [self updateCountFields];
}

-(void)changedChannel:(NSPopUpButton *)sender{
    [self.delegate changed:self.index for:sender.indexOfSelectedItem];
}

-(void)setTag:(NSInteger)atag{
    
    [self.background setWantsLayer:YES];
    [self.background.layer
     setBackgroundColor:atag%2 == 0?[[NSColor whiteColor] CGColor]: [[NSColor colorWithWhite:0.97 alpha:1.0f] CGColor]];
    self.index = atag;
    [self updateCountFields];
}

-(void)setLocalIndex:(NSInteger)localIndex{
    _localIndex = localIndex;
    NSColor *color = [NSColor colorInHueAtIndex:localIndex totalColors:[self.delegate numberOfChannels] withColoringType:[self.delegate typeOfColoring] minumAmountColors:3];

    if(!color){
        if([self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_COLOR])
            color = [NSColor colorFromHexString:[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_COLOR]];
        else
            color = [NSColor colorInHueAtIndex:localIndex totalColors:[self.delegate numberOfChannels] withColoringType:2 minumAmountColors:3];
    }
    
    self.color.color = color;
    
    //[self.selectChannel selectItemAtIndex:localIndex];
    [self.selectChannel selectItemWithTitle:self.channels[MIN(self.index, self.channels.count - 1)]];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
