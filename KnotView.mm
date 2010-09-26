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

#import <QuartzCore/CAAnimation.h>

#import "KnotDocument.h"
#import "KnotEngine.h"
#import "KnotModel.h"
#import "KnotStyle.h"

namespace
{
    const CGFloat kSectionSize = 80;
    const CGFloat kMinimumDisplayedSectionSize = 5;
    const CGFloat kMaxZoom = kSectionSize / kMinimumDisplayedSectionSize;
    const CGFloat kZoomFactor = 1.6;

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
    KnotStyle *pStyle = (style & BROAD) ? kpBroadStyle : kpSlenderStyle;
    bool hollow = !!(style & HOLLOW);
    engine = [[KnotEngine alloc] initWithStyle: pStyle hollow: hollow];

    [self setNeedsDisplay: YES];
}

- (id) initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self) {
        [self setBoundsOrigin: NSMakePoint(-0.5 * NSWidth(frame),
                                           -0.5 * NSHeight(frame))];

        tilingMode = HORIZONTAL | VERTICAL;
        style = 0;
        [self appearanceChanged];

        selX = selY = 0;
        selCorner = false;

        [[NSNotificationCenter defaultCenter]
         addObserver: self
            selector: @selector(updateCursor:)
                name: NSWindowDidBecomeKeyNotification
              object: nil];
        [[NSNotificationCenter defaultCenter]
         addObserver: self
            selector: @selector(updateCursor:)
                name: NSWindowDidResignKeyNotification
              object: nil];

        [self setWantsLayer: YES];
    }
    return self;
}

- (KnotEngine *) engine
{
    return engine;
}

#pragma mark Drawing

- (NSBezierPath *) selectionPath
{
    CGFloat delta = 0.5 * kSectionSize;
    NSBezierPath *path = [NSBezierPath bezierPath];

    [path moveToPoint: NSMakePoint(selX * kSectionSize,
                                   selY * kSectionSize)];
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

    int minX = (int)floor(NSMinX(dirtyRect) / kSectionSize);
    int maxX = (int) ceil(NSMaxX(dirtyRect) / kSectionSize);
    int minY = (int)floor(NSMinY(dirtyRect) / kSectionSize);
    int maxY = (int) ceil(NSMaxY(dirtyRect) / kSectionSize);

    KnotModel *model = document.model;
    for (int y = minY; y <= maxY; ++y) {
        bool inY = y >= model.minY && y <= model.maxY;

        for (int x = minX; x <= maxX; ++x) {
            bool inX = x >= model.minX && x <= model.maxX;
            NSRect dest = NSMakeRect((x - 0.5) * kSectionSize,
                                     (y - 0.5) * kSectionSize,
                                     kSectionSize,
                                     kSectionSize);

            dest = [self centerScanRect: dest];
            NSSize pixelSize = [self convertSizeToBase: dest.size];

            if ((inX || (tilingMode & HORIZONTAL))
                && (inY || (tilingMode & VERTICAL)))
            {
                int sx = (x - model.minX) % model.width;
                sx = model.minX + sx + (sx < 0 ? model.width : 0);
                int sy = (y - model.minY) % model.height;
                sy = model.minY + sy + (sy < 0 ? model.height : 0);

                [engine drawSection: [model sectionAtX: sx atY: sy]
                             inRect: dest
                       sizeInPixels: pixelSize
                          operation: NSCompositeSourceOver
                           fraction: ((inX && inY) ? 1.0 : 0.5)];
            } else {
                [engine drawSection: kEmptySection
                             inRect: dest
                       sizeInPixels: pixelSize
                          operation: NSCompositeSourceOver
                           fraction: 0.5];
            }
        }
    }

    // Draw cursor only when window is the key window.
    if ([[self window] isKeyWindow]) {
        NSBezierPath *selPath = [self selectionPath];
        [[NSColor colorWithCalibratedRed: 1.0
                                   green: 0.6
                                    blue: 0.6
                                   alpha: 0.5] set];
        [selPath fill];
        [[NSColor colorWithCalibratedRed: 1.0
                                   green: 0.0
                                    blue: 0.0
                                   alpha: 0.5] set];
        [selPath stroke];
    }
}

#pragma mark UI Actions

- (IBAction) setTilingMode: (id)sender
{
    tilingMode = [[sender cell] tagForSegment: [sender selectedSegment]];
    [self setNeedsDisplay: YES];
}

- (IBAction) setStyle: (id)sender;
{
    style = [[sender cell] tagForSegment: [sender selectedSegment]];
    [self appearanceChanged];
}

#pragma mark Resizing, Zooming and Panning

- (void) setFrameSize: (NSSize)newSize
{
    NSRect bounds= [self bounds];

    [super setFrameSize: newSize];
    newSize = [self convertSize: newSize fromView: nil];

    [self setBoundsOrigin: NSMakePoint(NSMidX(bounds) - 0.5 * newSize.width,
                                       NSMidY(bounds) - 0.5 * newSize.height)];
}

static void zoomBy(id view, CGFloat factor)
{
    NSRect frame = [view frame];
    NSRect bounds = [view bounds];
    CGFloat newZoom = min(kMaxZoom, NSWidth(bounds) / NSWidth(frame) / factor);
    CGFloat newWidth = NSWidth(frame) * newZoom;
    CGFloat newHeight = NSHeight(frame) * newZoom;

    [view setBounds: NSMakeRect(NSMidX(bounds) - 0.5 * newWidth,
                                NSMidY(bounds) - 0.5 * newHeight,
                                newWidth,
                                newHeight)];
    [[view engine] flushCache];
}

- (IBAction) zoom: (id)sender
{
    switch ([[sender cell] tagForSegment: [sender selectedSegment]]) {

    case 0: // "Zoom In"
        zoomBy([self animator], kZoomFactor);
        break;

    case 1: // "Zoom Out"
        zoomBy([self animator], 1.0 / kZoomFactor);
        break;
    }
}

- (void) magnifyWithEvent: (NSEvent *)event
{
    // NB: We don't animate this.
    zoomBy(self, 1.0 + [event magnification]);
}

- (void) scrollWheel: (NSEvent *)event
{
    // NB: We don't animate this either.
    zoomBy(self, pow(kZoomFactor, 0.3 * [event deltaY]));
}

- (void) mouseDragged: (NSEvent *)event
{
    NSPoint origin = [self convertPoint: [self bounds].origin toView: nil];
    origin = NSMakePoint(origin.x - [event deltaX], origin.y + [event deltaY]);

    // NB: And neither do we try to animate this.
    [self setBoundsOrigin: [self convertPoint: origin fromView: nil]];
}

- (IBAction) centerAndFit: (id)sender
{
    NSRect frame = [self frame];
    KnotModel *model = document.model;
    CGFloat sectionWidth = NSWidth(frame) / (model.width + 1);
    CGFloat sectionHeight = NSHeight(frame) / (model.height + 1);
    CGFloat newZoom = max(kSectionSize / max(min(sectionWidth, sectionHeight),
                                             kMinimumDisplayedSectionSize),
                          1.0);
    CGFloat newWidth = NSWidth(frame) * newZoom;
    CGFloat newHeight = NSHeight(frame) * newZoom;

    CGFloat midX = kSectionSize * (model.minX + (model.width - 1) * 0.5);
    CGFloat midY = kSectionSize * (model.minY + (model.height - 1) * 0.5);

    [[self animator] setBounds: NSMakeRect(midX - 0.5 * newWidth,
                                           midY - 0.5 * newHeight,
                                           newWidth,
                                           newHeight)];
    [engine flushCache];
}

#pragma mark Cursor Movement and Editing

- (BOOL) acceptsFirstResponder
{
    return YES;
}

- (void) updateCursor: (NSNotification *)notification
{
    if ([notification object] == [self window]) {
        [self setNeedsDisplayInRect: [[self selectionPath] bounds]];
    }
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

- (void) mouseDown: (NSEvent *)event
{
    NSPoint location = [self convertPoint: [event locationInWindow]
                                 fromView: nil];

    // Convert to skewed coordinates.
    int d1 =  (int)round((location.x + location.y) / kSectionSize);
    int d2 = -(int)round((location.x - location.y) / kSectionSize);

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

@end
