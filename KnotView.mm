//  Custom view for displaying knots.
//
//  Copyright © 2010  Jens Kilian
//
//  This file is part of Beltane.
//
//  Beltane is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Beltane is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Beltane.  If not, see <http://www.gnu.org/licenses/>.

#import "KnotView.h"

#include <cmath>
#include <algorithm>
using namespace ::std;

#import "KnotDocument.h"
#import "KnotEngine.h"
#import "KnotModel.h"
#import "KnotStyle.h"

namespace
{
    const CGFloat kZoomFactor = 1.2;
    const CGFloat kInitialSectionSize = 80.0;
    const CGFloat kMinimumSectionSize = 5;

    KnotStyle *kpSlenderStyle;
    KnotStyle *kpBroadStyle;
}

@implementation KnotView

+ (void) initialize
{
    if (self == [KnotView class]) {
        kpSlenderStyle = [[KnotStyle alloc] initWithName: @"slender"];
        kpBroadStyle   = [[KnotStyle alloc] initWithName: @"broad"];
    }
}

- (void) appearanceChanged
{
    engine = [[KnotEngine alloc] initWithStyle: style hollow: hollow];
    [self setNeedsDisplay: YES];
}

- (id) initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self) {
        [self setBoundsOrigin: NSMakePoint(-0.5 * NSWidth(frame),
                                           -0.5 * NSHeight(frame))];

        style = kpSlenderStyle;
        hollow = false;
        sectionSize = kInitialSectionSize;
        [self appearanceChanged];

        selX = selY = 0;
        selCorner = false;
    }
    return self;
}

- (NSBezierPath *) selectionPath
{
    CGFloat delta = 0.5 * sectionSize;
    NSBezierPath *path = [NSBezierPath bezierPath];

    [path moveToPoint: NSMakePoint(selX * sectionSize,
                                   selY * sectionSize)];
    if (selCorner) {
        [path relativeMoveToPoint: NSMakePoint(-delta, -delta)];
    }

    [path relativeMoveToPoint: NSMakePoint(0, delta)];
    [path relativeLineToPoint: NSMakePoint(delta, -delta)];
    [path relativeLineToPoint: NSMakePoint(-delta, -delta)];
    [path relativeLineToPoint: NSMakePoint(-delta, delta)];
    [path closePath];

    return path;
}

- (void) drawRect: (NSRect)dirtyRect
{
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect: dirtyRect];

    int minX = (int)floor(NSMinX(dirtyRect) / sectionSize);
    int maxX = (int) ceil(NSMaxX(dirtyRect) / sectionSize);
    int minY = (int)floor(NSMinY(dirtyRect) / sectionSize);
    int maxY = (int) ceil(NSMaxY(dirtyRect) / sectionSize);

    for (int y = minY; y <= maxY; ++y) {
        for (int x = minX; x <= maxX; ++x) {
            NSRect dest = NSMakeRect((x - 0.5) * sectionSize,
                                     (y - 0.5) * sectionSize,
                                     sectionSize,
                                     sectionSize);

            KnotModel *model = document.model;
            int sx = (x - model.minX) % model.width;
            sx = model.minX + sx + (sx < 0 ? model.width : 0);
            int sy = (y - model.minY) % model.height;
            sy = model.minY + sy + (sy < 0 ? model.height : 0);

            [engine drawSection: [model getSectionAtX: sx atY: sy]
                         inRect: dest
                      operation: NSCompositeSourceOver
                       fraction: ([model hasSectionAtX: x atY: y]
                                  ? 1.0
                                  : 0.5)];
        }
    }

    // TODO - draw cursor only when window is the key window
    NSBezierPath *selPath = [self selectionPath];
    [[NSColor colorWithCalibratedRed: 1.0 green: 0.6 blue: 0.6 alpha: 0.5] set];
    [selPath fill];
    [[NSColor colorWithCalibratedRed: 1.0 green: 0.0 blue: 0.0 alpha: 0.5] set];
    [selPath stroke];
}

- (BOOL) acceptsFirstResponder
{
    return YES;
}

- (BOOL) validateMenuItem: (NSMenuItem *)menuItem
{
    SEL action = [menuItem action];

    if (action == @selector(toggleStyle:)) {
        NSInteger state = NSOffState;

        switch ([menuItem tag]) {

        case 0: // "Broad Strokes"
            state = (style == kpBroadStyle) ? NSOnState : NSOffState;
            break;

        case 1: // "Hollow Strokes"
            state = hollow ? NSOnState : NSOffState;
            break;
        }

        [menuItem setState: state];
    }

    return YES;
}

- (IBAction) toggleStyle: (id)sender;
{
    switch ([sender tag]) {

    case 0: // "Broad Strokes"
        style = (style == kpSlenderStyle) ? kpBroadStyle : kpSlenderStyle;
        break;

    case 1: // "Hollow Strokes"
        hollow = !hollow;
        break;
    }
    [self appearanceChanged];
}

- (IBAction) zoom: (id)sender
{
    switch ([sender tag]) {

    case 0: // "Zoom In"
        sectionSize *= kZoomFactor;
        break;

    case 1: // "Zoom Out"
        sectionSize = max(sectionSize / kZoomFactor, kMinimumSectionSize);
        break;
    }
    [self setNeedsDisplay: YES];
}

- (void) magnifyWithEvent: (NSEvent *)event
{
    sectionSize = max(sectionSize * (1.0 + [event magnification]),
                      kMinimumSectionSize);
    [self setNeedsDisplay: YES];
}

- (void) keyDown: (NSEvent *)event
{
    NSString *chars = [[event characters] uppercaseString];
    if ([chars length] == 1) {
        unichar c = [chars characterAtIndex: 0];

        switch (c) {

        case 'X': // I keep hitting this instead of 'D' :-)
            c = 'D';
        case 'D': case 'H': case 'V': case 'N':
            if (selCorner) {
                [document setCornerType: (char)c atX: selX atY: selY];
            } else {
                [document setSectionType: (char)c atX: selX atY: selY];
            }
            return;
        }
    }

    [super keyDown: event];
}

- (void) mouseDown: (NSEvent *)event
{
    NSPoint location = [self convertPoint: [event locationInWindow]
                                 fromView: nil];

    // Convert to skewed coordinates.
    int d1 =  (int)round((location.x + location.y) / sectionSize);
    int d2 = -(int)round((location.x - location.y) / sectionSize);

    if ((d1 + d2) % 2) {
        selX = (d1-d2+1) / 2;
        selY = (d1+d2+1) / 2;
        selCorner = true;

    } else {
        selX = (d1-d2) / 2;
        selY = (d1+d2) / 2;
        selCorner = false;
    }

    [self setNeedsDisplay: YES];
}

@end
