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

    const KnotStyle *kpSlenderStyle;
    const KnotStyle *kpBroadStyle;

    const KnotSection kEmptySection('N', 'N', 'N', 'N', 'N');
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

        tilingMode = HORIZONTAL | VERTICAL;
        style = kpSlenderStyle;
        hollow = false;
        sectionSize = kInitialSectionSize;
        [self appearanceChanged];

        selX = selY = 0;
        selCorner = false;
    }
    return self;
}

- (void) setFrameSize: (NSSize)newSize
{
    NSRect oldBounds = [self bounds];

    [super setFrameSize: newSize];

    CGFloat midX = NSMidX(oldBounds);
    CGFloat midY = NSMidY(oldBounds);
    [self setBoundsOrigin: NSMakePoint(midX - 0.5 * newSize.width,
                                       midY - 0.5 * newSize.height)];
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

    KnotModel *model = document.model;
    for (int y = minY; y <= maxY; ++y) {
        bool inY = y >= model.minY && y <= model.maxY;

        for (int x = minX; x <= maxX; ++x) {
            bool inX = x >= model.minX && x <= model.maxX;

            NSRect dest = NSMakeRect((x - 0.5) * sectionSize,
                                     (y - 0.5) * sectionSize,
                                     sectionSize,
                                     sectionSize);

            if ((inX || (tilingMode & HORIZONTAL))
                && (inY || (tilingMode & VERTICAL)))
            {
                int sx = (x - model.minX) % model.width;
                sx = model.minX + sx + (sx < 0 ? model.width : 0);
                int sy = (y - model.minY) % model.height;
                sy = model.minY + sy + (sy < 0 ? model.height : 0);

                [engine drawSection: [model sectionAtX: sx atY: sy]
                             inRect: dest
                          operation: NSCompositeSourceOver
                           fraction: ((inX && inY) ? 1.0 : 0.5)];
            } else {
                [engine drawSection: kEmptySection
                             inRect: dest
                          operation: NSCompositeSourceOver
                           fraction: 0.5];
            }
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

- (IBAction) setTilingMode: (id)sender
{
    tilingMode = [[sender cell] tagForSegment: [sender selectedSegment]];
    [self setNeedsDisplay: YES];
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

- (void) zoomBy: (CGFloat)factor
{
    sectionSize = max(kMinimumSectionSize, factor * sectionSize);
    [self setNeedsDisplay: YES];
}

- (IBAction) zoom: (id)sender
{
    switch ([sender tag]) {

    case 0: // "Zoom In"
        [self zoomBy: kZoomFactor];
        break;

    case 1: // "Zoom Out"
        [self zoomBy: 1.0 / kZoomFactor];
        break;
    }
}

- (void) magnifyWithEvent: (NSEvent *)event
{
    [self zoomBy: 1.0 + [event magnification]];
}

- (void) scrollWheel: (NSEvent *)event
{
    [self zoomBy: pow(kZoomFactor, 0.3 * [event deltaY])];
}

- (void) moveCursorByX: (int)dx byY:(int)dy
{
    selX += dx;
    selY += dy;
    [self setNeedsDisplay: YES];
}

- (void) moveLeft: (id)sender
{
    [self moveCursorByX: -1 byY: 0];
}

- (void) moveRight: (id)sender
{
    [self moveCursorByX: 1 byY: 0];
}

- (void) moveDown: (id)sender
{
    [self moveCursorByX: 0 byY: -1];
}

- (void) moveUp: (id)sender
{
    [self moveCursorByX: 0 byY: 1];
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

- (void) mouseDragged: (NSEvent *)event
{
    NSPoint origin = [self bounds].origin;
    [self setBoundsOrigin: NSMakePoint(origin.x - [event deltaX],
                                       origin.y + [event deltaY])];
    [self setNeedsDisplay: YES];
}

@end
