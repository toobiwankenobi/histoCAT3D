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
    //SPF: allow 0 = filter off (the slider in the XIB starts at 1, so the filter was always on once touched)
    self.pixelFilter.minValue = 0;
    self.pixelFilterField = [self countFieldNextToSlider:self.pixelFilter
                                                 toolTip:@"Single pixel filter (0 = off)"];
    [self addHelpButton];
    [self addToolTips];
}

#pragma mark help

-(void)addHelpButton{
    if(!self.color)
        return;
    NSRect colorFrame = self.color.frame;
    NSButton *help = [[NSButton alloc]initWithFrame:NSMakeRect(NSMaxX(colorFrame) + 3, NSMidY(colorFrame) - 11, 21, 21)];
    help.bezelStyle = NSBezelStyleHelpButton;
    help.title = @"";
    help.target = self;
    help.action = @selector(showHelp:);
    help.toolTip = @"What do these controls do?";
    help.autoresizingMask = self.color.autoresizingMask;
    [self.color.superview addSubview:help];
    self.helpButton = help;
}

-(void)addToolTips{
    NSDictionary *tips = @{
        @"Max":    @"Upper limit of the display in counts. Values at or above are shown at full brightness. Lower = brighter image.",
        @"Offset": @"Values below this (in counts) are shown black. Set as a fraction of Max, so it follows Max and Mult.",
        @"Mult":   @"Brightness multiplier. Divides the displayed range: Max (and Offset) shrink by this factor.",
        @"SPF":    @"Single pixel filter: removes isolated bright pixels (noise). 0 = off."
    };
    NSDictionary *controls = @{@"Max": self.maxOffset ?: [NSNull null], @"Offset": self.offset ?: [NSNull null],
                               @"Mult": self.multiplier ?: [NSNull null], @"SPF": self.pixelFilter ?: [NSNull null]};
    for (NSView *view in self.subviews) {
        if(![view isKindOfClass:[NSTextField class]] || [(NSTextField *)view isEditable])
            continue;
        NSString *tip = tips[[(NSTextField *)view stringValue]];
        if(tip)
            view.toolTip = tip;
    }
    for (NSString *key in controls) {
        id control = controls[key];
        if(control != [NSNull null])
            [control setToolTip:tips[key]];
    }
    self.transformData.toolTip = @"UT = untransformed counts, Log = logarithm, Asinh = arcsinh(counts/5). Log and Asinh make dim structures easier to see.";
    self.color.toolTip = @"Channel colour (available when the colouring mode is set to custom colours)";
}

-(NSAttributedString *)helpText{
    NSArray *entries = @[
        @[@"Max", @"Upper limit of the display, in counts. Values at or above Max are shown at full brightness. Lower Max = brighter image."],
        @[@"Offset", @"Values below the offset (in counts) are shown black. Use it to remove background signal. Internally it is a fraction of Max, so it moves together with Max and Mult."],
        @[@"Mult", @"Brightness multiplier (1–10). It divides the displayed range: with Mult 2, Max and Offset are halved and the image gets brighter. The number fields always show the resulting range in counts."],
        @[@"SPF", @"Single pixel filter. Removes isolated bright pixels (noise) that are much brighter than their surroundings. 0 = off; higher values filter more strongly and can also remove small, dim structures. Slows down redrawing."],
        @[@"UT / Log / Asinh", @"Transformation of the counts: untransformed, logarithm, or arcsinh(counts / 5). Log and Asinh compress bright values so that dim structures become visible. The number fields for Max and Offset only work with UT."],
        @[@"Colour", @"Colour of the channel. Can be changed when the colouring mode is set to custom colours."],
        @[@"Number fields", @"Type a value and press Return or Tab. The slider moves to match. Values outside the slider range are clamped."]
    ];
    NSFont *bold = [NSFont boldSystemFontOfSize:11];
    NSFont *regular = [NSFont systemFontOfSize:11];
    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc]init];
    para.paragraphSpacing = 6;
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc]init];
    for (NSArray *entry in entries) {
        [text appendAttributedString:[[NSAttributedString alloc]initWithString:[entry[0] stringByAppendingString:@": "]
                                                                    attributes:@{NSFontAttributeName: bold, NSParagraphStyleAttributeName: para, NSForegroundColorAttributeName: [NSColor labelColor]}]];
        [text appendAttributedString:[[NSAttributedString alloc]initWithString:[entry[1] stringByAppendingString:@"\n"]
                                                                    attributes:@{NSFontAttributeName: regular, NSParagraphStyleAttributeName: para, NSForegroundColorAttributeName: [NSColor labelColor]}]];
    }
    [text appendAttributedString:[[NSAttributedString alloc]initWithString:@"These settings only change the display, not the underlying data."
                                                                attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:11 weight:NSFontWeightRegular], NSForegroundColorAttributeName: [NSColor secondaryLabelColor]}]];
    return text;
}

-(void)showHelp:(NSButton *)sender{
    if(self.helpPopover.isShown){
        [self.helpPopover close];
        return;
    }
    const CGFloat width = 320, margin = 14;
    NSTextField *label = [NSTextField wrappingLabelWithString:@""];
    label.attributedStringValue = [self helpText];
    label.selectable = NO;
    label.preferredMaxLayoutWidth = width;
    NSSize size = [label.cell cellSizeForBounds:NSMakeRect(0, 0, width, CGFLOAT_MAX)];
    label.frame = NSMakeRect(margin, margin, width, size.height);

    NSView *content = [[NSView alloc]initWithFrame:NSMakeRect(0, 0, width + 2 * margin, size.height + 2 * margin)];
    [content addSubview:label];
    NSViewController *controller = [[NSViewController alloc]init];
    controller.view = content;

    NSPopover *popover = [[NSPopover alloc]init];
    popover.contentViewController = controller;
    popover.contentSize = content.frame.size;
    popover.behavior = NSPopoverBehaviorTransient;
    self.helpPopover = popover;
    [popover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSRectEdgeMaxX];
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
    self.pixelFilterField.floatValue = self.pixelFilter.floatValue;

    float max = [self channelMax];
    BOOL usable = max > .0f && [self countsAreLinear];
    self.maxCountField.enabled = usable;
    self.offsetCountField.enabled = usable;
    if(!usable){
        self.maxCountField.stringValue = @"";
        self.offsetCountField.stringValue = @"";
        return;
    }
    //Both fields show the range that is actually displayed, in counts:
    //values >= Max are full brightness, values < Offset are black. Mult divides that range.
    float mult = MAX(self.multiplier.floatValue, 1e-6f);
    float displayedMax = max * self.maxOffset.floatValue / mult;
    self.maxCountField.floatValue = displayedMax;
    self.offsetCountField.floatValue = self.offset.floatValue * displayedMax;
}

-(void)enteredCount:(NSTextField *)sender{
    //Remember the slider values to skip the (expensive) image refresh if nothing changed,
    //e.g. when a field merely loses focus because the user clicks a slider
    double oldMax = self.maxOffset.doubleValue, oldOffset = self.offset.doubleValue,
           oldMult = self.multiplier.doubleValue, oldSPF = self.pixelFilter.doubleValue;

    if(sender == self.multiplierField){
        self.multiplier.floatValue = MIN(self.multiplier.maxValue, MAX(self.multiplier.minValue, sender.floatValue));
    }else if(sender == self.pixelFilterField){
        self.pixelFilter.floatValue = MIN(self.pixelFilter.maxValue, MAX(self.pixelFilter.minValue, sender.floatValue));
    }else{
        float max = [self channelMax];
        if(max <= .0f || ![self countsAreLinear]){
            [self updateCountFields];
            return;
        }
        float value = MAX(.0f, sender.floatValue);
        float mult = MAX(self.multiplier.floatValue, 1e-6f);
        if(sender == self.maxCountField){
            //Never exactly 0 (the image generator divides by it), but allow down to 0.01 counts
            value = MIN(max, MAX(value, 0.01f));
            //If the value is out of reach with the current Mult, lower Mult so it can be displayed
            if(value * mult > max){
                mult = MAX((float)self.multiplier.minValue, max / value);
                self.multiplier.floatValue = mult;
            }
            self.maxOffset.floatValue = MIN(1.0f, value * mult / max);
        }else if(sender == self.offsetCountField){
            float displayedMax = max * self.maxOffset.floatValue / mult;
            self.offset.floatValue = displayedMax > .0f ? MIN(1.0f, value / displayedMax) : .0f;
        }
    }

    if(self.maxOffset.doubleValue == oldMax && self.offset.doubleValue == oldOffset &&
       self.multiplier.doubleValue == oldMult && self.pixelFilter.doubleValue == oldSPF){
        [self updateCountFields];//just reformat the field
        return;
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
