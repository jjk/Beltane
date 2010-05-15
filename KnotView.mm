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

- (id) initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self) {
        sectionSize = kInitialSectionSize;
        engine = [[KnotEngine alloc] initWithStyle: kpSlenderStyle
                                            hollow: true];

        selX = selY = 0;
        selCorner = false;
    }
    return self;
}

- (NSBezierPath *) selectionPath
{
    CGFloat delta = 0.5 * sectionSize;
    NSBezierPath *path = [NSBezierPath bezierPath];

    [path moveToPoint: NSMakePoint( selX * sectionSize,
                                   -selY * sectionSize)];
    if (selCorner) {
        [path relativeMoveToPoint: NSMakePoint(-delta, delta)];
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

    NSRect bounds = [self bounds];
    NSRect rect = NSOffsetRect(dirtyRect,
                               -0.5 * NSWidth(bounds),
                               -0.5 * NSHeight(bounds));

    int minX = (int)floor(NSMinX(rect) / sectionSize);
    int maxX = (int) ceil(NSMaxX(rect) / sectionSize);
    int minY = (int)floor(NSMinY(rect) / sectionSize);
    int maxY = (int) ceil(NSMaxY(rect) / sectionSize);

    NSAffineTransform *xl = [NSAffineTransform transform];
    [xl translateXBy: 0.5 * NSWidth(bounds)
                 yBy: 0.5 * NSHeight(bounds)];
    [xl concat];

    for (int y = minY; y <= maxY; ++y) {
        for (int x = minX; x <= maxX; ++x) {
            NSRect dest = NSMakeRect(( x - 0.5) * sectionSize,
                                     (-y - 0.5) * sectionSize,
                                     sectionSize,
                                     sectionSize);

            int sx = (x - document.minX) % document.width;
            sx = document.minX + sx + (sx < 0 ? document.width : 0);
            int sy = (y - document.minY) % document.height;
            sy = document.minY + sy + (sy < 0 ? document.height : 0);

            [engine drawSection: [document getSectionAtX: sx atY: sy]
                         inRect: dest
                      operation: NSCompositeSourceOver
                       fraction: ([document hasSectionAtX: x atY: y]
                                  ? 1.0
                                  : 0.5)];
        }
    }

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

- (IBAction) zoomIn: (id)sender
{
    sectionSize *= kZoomFactor;
    [self setNeedsDisplay: YES];
}

- (IBAction) zoomOut: (id)sender
{
    sectionSize = max(sectionSize / kZoomFactor, kMinimumSectionSize);
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

        case 'D': case 'H': case 'V': case 'N':
            if (selCorner) {
                [document setCornerType: (char)c atX: selX atY: selY];
            } else {
                [document setSectionType: (char)c atX: selX atY: selY];
            }
            [self setNeedsDisplay: YES];
            return;
        }
    }

    [super keyDown: event];
}

- (void) mouseDown: (NSEvent *)event
{
    NSPoint location = [self convertPoint: [event locationInWindow]
                                 fromView: nil];
    NSRect bounds = [self bounds];
    NSPoint pt = NSMakePoint(location.x - 0.5 * NSWidth(bounds),
                             location.y - 0.5 * NSHeight(bounds));

    // Convert to skewed coordinates.
    int d1 =  (int)round((pt.x - pt.y) / sectionSize);
    int d2 = -(int)round((pt.x + pt.y) / sectionSize);

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
