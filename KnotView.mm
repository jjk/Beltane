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
    const CGFloat kZoomFactor = 1.6;
    const CGFloat kInitialSectionSize = 80;
    const CGFloat kMinimumSectionSize = 8;

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

+ (id) defaultAnimationForKey: (NSString *)key
{
    if ([key isEqualToString: @"sectionSize"]) {
        return [CABasicAnimation animation];
    }

    return [super defaultAnimationForKey:key];
}

- (void) appearanceChanged
{
    KnotStyle *pStyle = (style & BROAD) ? kpBroadStyle : kpSlenderStyle;
    bool hollow = !!(style & HOLLOW);
    engine = [[KnotEngine alloc] initWithStyle: pStyle hollow: hollow];

    [self setNeedsDisplay: YES];
}

- (CGFloat) sectionSize
{
    return sectionSize;
}

- (void) setSectionSize: (CGFloat)newSize
{
    if (sectionSize != newSize) {
        sectionSize = newSize;
        [engine flushCache];
        [self setNeedsDisplay: YES];
    }
}

- (id) initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self) {
        [self setBoundsOrigin: NSMakePoint(-0.5 * NSWidth(frame),
                                           -0.5 * NSHeight(frame))];

        tilingMode = HORIZONTAL | VERTICAL;
        style = 0;
        sectionSize = kInitialSectionSize;
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

#pragma mark Drawing

- (BOOL) isOpaque
{
    return YES;
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

    NSSize pixelSize = NSMakeSize(sectionSize, sectionSize);

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
    NSRect bounds = [self bounds];
    NSPoint origin = NSMakePoint(NSMidX(bounds) - 0.5 * newSize.width,
                                 NSMidY(bounds) - 0.5 * newSize.height);

    [super setFrameSize: newSize];
    [self setBoundsOrigin: origin];
}

static void zoomBy(id view, CGFloat factor)
{
    CGFloat oldSectionSize = [view sectionSize];
    CGFloat newSectionSize = max(kMinimumSectionSize, factor * oldSectionSize);

    NSRect bounds = [view bounds];
    CGFloat cx = NSMidX(bounds) * newSectionSize / oldSectionSize;
    CGFloat cy = NSMidY(bounds) * newSectionSize / oldSectionSize;
    NSPoint origin = NSMakePoint(cx - 0.5 * NSWidth(bounds),
                                 cy - 0.5 * NSHeight(bounds));

    [view setSectionSize: newSectionSize];
    [view setBoundsOrigin: origin];
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
    NSPoint origin = [self bounds].origin;
    origin.x -= [event deltaX];
    origin.y += [event deltaY];

    // NB: And neither do we try to animate this.
    [self setBoundsOrigin: origin];
}

- (IBAction) centerAndFit: (id)sender
{
    NSRect bounds = [self bounds];
    CGFloat boundsWidth = NSWidth(bounds);
    CGFloat boundsHeight = NSHeight(bounds);

    KnotModel *model = document.model;
    CGFloat sectionWidth = boundsWidth / (model.width + 1);
    CGFloat sectionHeight = boundsHeight / (model.height + 1);
    CGFloat newSectionSize = min(max(min(sectionWidth, sectionHeight),
                                     kMinimumSectionSize),
                                 kInitialSectionSize);

    CGFloat dx = newSectionSize * (model.minX - 0.5);
    CGFloat dy = newSectionSize * (model.minY - 0.5);
    CGFloat w  = newSectionSize * model.width;
    CGFloat h  = newSectionSize * model.height;
    NSPoint origin = NSMakePoint(dx + 0.5 * (w - boundsWidth),
                                 dy + 0.5 * (h - boundsHeight));

    [[self animator] setSectionSize: newSectionSize];
    [[self animator] setBoundsOrigin: origin];
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
