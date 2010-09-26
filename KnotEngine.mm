//  Description of knot strokes and sections.
//
//  Copyright © 1997-2010  Jens Kilian
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

#import "KnotEngine.h"

#include "KnotSection.h"
#import "KnotStyle.h"
#import "Stroke.h"
#import "StrokeSet.h"

namespace
{
    // Transformations.
    const NSAffineTransformStruct kTransformation[8] = {
        {  1,  0,  0,  1,  0,  0 },
        {  0,  1, -1,  0,  0,  0 },
        { -1,  0,  0, -1,  0,  0 },
        {  0, -1,  1,  0,  0,  0 },
        { -1,  0,  0,  1,  0,  0 },
        {  0, -1, -1,  0,  0,  0 },
        {  1,  0,  0, -1,  0,  0 },
        {  0,  1,  1,  0,  0,  0 }
    };
}

@implementation KnotEngine

- (id) initWithStyle: (KnotStyle *)style hollow: (bool)hollow
{
    self = [super init];
    if (self) {
        mpStyle = style;
        mHollow = hollow;

        mpCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) drawErrorIndicatorInRect: (NSRect)rect
{
    rect = NSInsetRect(rect, 0.25 * NSWidth(rect), 0.25 * NSHeight(rect));

    [[NSColor magentaColor] setFill];
    [[NSBezierPath bezierPathWithOvalInRect: rect] fill];
}

- (void) drawStroke: (Stroke *)stroke
        transformed: (int)transformation
             inRect: (NSRect)rect
          operation: (NSCompositingOperation)op
{
    NSAffineTransform *t = [NSAffineTransform transform];
    [t setTransformStruct: kTransformation[transformation]];
    [t concat];

    NSImage *image = [stroke image];
    [image drawInRect: rect fromRect: NSZeroRect operation: op fraction: 1.0];

    [t invert];
    [t concat];
}

- (void) drawCornerStrokesFromSet: (StrokeSet *)strokes
                       forSection: (const KnotSection &)section
                           inRect: (NSRect)rect
                        operation: (NSCompositingOperation)op
{
    Stroke *corner = [strokes strokeAt: Strokes::Corner];

    if (section.leftTop() == 'D') {
        [self drawStroke: corner transformed: 0 inRect: rect operation: op];
    }
    if (section.rightBottom() == 'D') {
        [self drawStroke: corner transformed: 2 inRect: rect operation: op];
    }
}

- (void) drawCornersForSection: (const KnotSection &)section
                        inRect: (NSRect)rect
{
    [self drawCornerStrokesFromSet: [mpStyle outline]
                        forSection: section
                            inRect: rect
                         operation: (mHollow
                                     ? NSCompositeSourceOver
                                     : NSCompositeDestinationOut)];
    [self drawCornerStrokesFromSet: [mpStyle fill]
                        forSection: section
                            inRect: rect
                         operation: (mHollow
                                     ? NSCompositeDestinationOut
                                     : NSCompositeSourceOver)];
}

- (void) drawDiagonalStrokeFromSet: (StrokeSet *)strokes
                              from: (char)from
                                to: (char)to
                          mirrored: (bool)mirror
                            inRect: (NSRect)rect
                         operation: (NSCompositingOperation)op
{
    switch ((from << 8) + to) {

    case ('D' << 8) + 'D':
        [self drawStroke: [strokes strokeAt: Strokes::DDD]
             transformed: (mirror ? 4 : 0)
                  inRect: rect
               operation: op];
        break;

    case ('D' << 8) + 'H':
        [self drawStroke: [strokes strokeAt: Strokes::DHD]
             transformed: (mirror ? 6 : 2)
                  inRect: rect
               operation: op];
        break;

    case ('D' << 8) + 'V':
        [self drawStroke: [strokes strokeAt: Strokes::DHD]
             transformed: (mirror ? 1 : 7)
                  inRect: rect
               operation: op];
        break;

    case ('H' << 8) + 'D':
        [self drawStroke: [strokes strokeAt: Strokes::DHD]
             transformed: (mirror ? 4 : 0)
                  inRect: rect
               operation: op];
        break;

    case ('H' << 8) + 'H':
        [self drawStroke: [strokes strokeAt: Strokes::DHH]
             transformed: (mirror ? 4 : 0)
                  inRect: rect
               operation: op];
        break;

    case ('H' << 8) + 'V':
        [self drawStroke: [strokes strokeAt: Strokes::DHV]
             transformed: (mirror ? 4 : 0)
                  inRect: rect
               operation: op];
        break;

    case ('V' << 8) + 'D':
        [self drawStroke: [strokes strokeAt: Strokes::DHD]
             transformed: (mirror ? 3 : 5)
                  inRect: rect
               operation: op];
        break;

    case ('V' << 8) + 'H':
        [self drawStroke: [strokes strokeAt: Strokes::DHV]
             transformed: (mirror ? 6 : 2)
                  inRect: rect
               operation: op];
        break;

    case ('V' << 8) + 'V':
        [self drawStroke: [strokes strokeAt: Strokes::DHH]
             transformed: (mirror ? 1 : 5)
                  inRect: rect
               operation: op];
        break;

    default:
        // TODO - indicate actual problem.
        [self drawErrorIndicatorInRect: rect];
        break;
    }
}

- (void) drawDiagonalSection: (const KnotSection &)section
                      inRect: (NSRect)rect
{
    // Draw bottom stroke.
    [self drawDiagonalStrokeFromSet: [mpStyle outline]
                               from: section.rightTop()
                                 to: section.leftBottom()
                           mirrored: true
                             inRect: rect
                          operation: (mHollow
                                      ? NSCompositeSourceOver
                                      : NSCompositeDestinationOut)];
    [self drawDiagonalStrokeFromSet: [mpStyle fill]
                               from: section.rightTop()
                                 to: section.leftBottom()
                           mirrored: true
                             inRect: rect
                          operation: (mHollow
                                      ? NSCompositeDestinationOut
                                      : NSCompositeSourceOver)];
    // Draw top stroke.
    [self drawDiagonalStrokeFromSet: [mpStyle outline]
                               from: section.leftTop()
                                 to: section.rightBottom()
                           mirrored: false
                             inRect: rect
                          operation: (mHollow
                                      ? NSCompositeSourceOver
                                      : NSCompositeDestinationOut)];
    [self drawDiagonalStrokeFromSet: [mpStyle fill]
                               from: section.leftTop()
                                 to: section.rightBottom()
                           mirrored: false
                             inRect: rect
                          operation: (mHollow
                                      ? NSCompositeDestinationOut
                                      : NSCompositeSourceOver)];
}

- (void) drawHorizontalStrokeFromSet: (StrokeSet *)strokes
                                from: (char)from
                                  to: (char)to
                            mirrored: (bool)mirror
                              inRect: (NSRect)rect
                           operation: (NSCompositingOperation)op
{
    switch ((from << 8) + to) {

    case ('D' << 8) + 'D':
        [self drawStroke: [strokes strokeAt: Strokes::HDD]
             transformed: (mirror ? 2 : 0)
                  inRect: rect
               operation: op];
        break;

    case ('D' << 8) + 'H':
        [self drawStroke: [strokes strokeAt: Strokes::HDH]
             transformed: (mirror ? 6 : 0)
                  inRect: rect
               operation: op];
        break;

    case ('D' << 8) + 'V':
        [self drawStroke: [strokes strokeAt: Strokes::HDV]
             transformed: (mirror ? 6 : 0)
                  inRect: rect
               operation: op];
        break;

    case ('H' << 8) + 'D':
        [self drawStroke: [strokes strokeAt: Strokes::HDH]
             transformed: (mirror ? 2 : 4)
                  inRect: rect
               operation: op];
        break;

    case ('H' << 8) + 'H':
        [self drawStroke: [strokes strokeAt: Strokes::HHH]
             transformed: (mirror ? 2 : 0)
                  inRect: rect
               operation: op];
        break;

    case ('H' << 8) + 'V':
        [self drawStroke: [strokes strokeAt: Strokes::HHV]
             transformed: (mirror ? 6 : 0)
                  inRect: rect
               operation: op];
        break;

    case ('V' << 8) + 'D':
        [self drawStroke: [strokes strokeAt: Strokes::HDV]
             transformed: (mirror ? 2 : 4)
                  inRect: rect
               operation: op];
        break;

    case ('V' << 8) + 'H':
        [self drawStroke: [strokes strokeAt: Strokes::HHV]
             transformed: (mirror ? 2 : 4)
                  inRect: rect
               operation: op];
        break;

    case ('V' << 8) + 'V':
        [self drawStroke: [strokes strokeAt: Strokes::HVV]
             transformed: (mirror ? 2 : 0)
                  inRect: rect
               operation: op];
        break;

    case ('D' << 8) + 'N':
    case ('H' << 8) + 'N':
    case ('V' << 8) + 'N':
    case ('N' << 8) + 'D':
    case ('N' << 8) + 'H':
    case ('N' << 8) + 'V':
    case ('N' << 8) + 'N':
        // Stroke omitted (edge or corner section).
        break;

    default:
        // TODO - indicate actual problem.
        [self drawErrorIndicatorInRect: rect];
        break;
    }
}

- (void) drawHorizontalSection: (const KnotSection &)section
                        inRect: (NSRect)rect
{
    // Draw bottom stroke.
    [self drawHorizontalStrokeFromSet: [mpStyle outline]
                                 from: section.leftBottom()
                                   to: section.rightBottom()
                             mirrored: true
                               inRect: rect
                            operation: (mHollow
                                        ? NSCompositeSourceOver
                                        : NSCompositeDestinationOut)];
    [self drawHorizontalStrokeFromSet: [mpStyle fill]
                                 from: section.leftBottom()
                                   to: section.rightBottom()
                             mirrored: true
                               inRect: rect
                            operation: (mHollow
                                        ? NSCompositeDestinationOut
                                        : NSCompositeSourceOver)];
    // Draw top stroke.
    [self drawHorizontalStrokeFromSet: [mpStyle outline]
                                 from: section.leftTop()
                                   to: section.rightTop()
                             mirrored: false
                               inRect: rect
                            operation: (mHollow
                                        ? NSCompositeSourceOver
                                        : NSCompositeDestinationOut)];
    [self drawHorizontalStrokeFromSet: [mpStyle fill]
                                 from: section.leftTop()
                                   to: section.rightTop()
                             mirrored: false
                               inRect: rect
                            operation: (mHollow
                                        ? NSCompositeDestinationOut
                                        : NSCompositeSourceOver)];
}

- (void) drawVerticalStrokeFromSet: (StrokeSet *)strokes
                              from: (char)from
                                to: (char)to
                          mirrored: (bool)mirror
                            inRect: (NSRect)rect
                         operation: (NSCompositingOperation)op
{
    switch ((from << 8) + to) {

    case ('D' << 8) + 'D':
        [self drawStroke: [strokes strokeAt: Strokes::HDD]
             transformed: (mirror ? 3 : 1)
                  inRect: rect
               operation: op];
        break;

    case ('D' << 8) + 'H':
        [self drawStroke: [strokes strokeAt: Strokes::HDV]
             transformed: (mirror ? 3 : 5)
                  inRect: rect
               operation: op];
        break;

    case ('D' << 8) + 'V':
        [self drawStroke: [strokes strokeAt: Strokes::HDH]
             transformed: (mirror ? 3 : 5)
                  inRect: rect
               operation: op];
        break;

    case ('H' << 8) + 'D':
        [self drawStroke: [strokes strokeAt: Strokes::HDV]
             transformed: (mirror ? 7 : 1)
                  inRect: rect
               operation: op];
        break;

    case ('H' << 8) + 'H':
        [self drawStroke: [strokes strokeAt: Strokes::HVV]
             transformed: (mirror ? 3 : 1)
                  inRect: rect
               operation: op];
        break;

    case ('H' << 8) + 'V':
        [self drawStroke: [strokes strokeAt: Strokes::HHV]
             transformed: (mirror ? 7 : 1)
                  inRect: rect
               operation: op];
        break;

    case ('V' << 8) + 'D':
        [self drawStroke: [strokes strokeAt: Strokes::HDH]
             transformed: (mirror ? 7 : 1)
                  inRect: rect
               operation: op];
        break;

    case ('V' << 8) + 'H':
        [self drawStroke: [strokes strokeAt: Strokes::HHV]
             transformed: (mirror ? 3 : 5)
                  inRect: rect
               operation: op];
        break;

    case ('V' << 8) + 'V':
        [self drawStroke: [strokes strokeAt: Strokes::HHH]
             transformed: (mirror ? 3 : 1)
                  inRect: rect
               operation: op];
        break;

    case ('D' << 8) + 'N':
    case ('H' << 8) + 'N':
    case ('V' << 8) + 'N':
    case ('N' << 8) + 'D':
    case ('N' << 8) + 'H':
    case ('N' << 8) + 'V':
    case ('N' << 8) + 'N':
        // Stroke omitted (edge or corner section).
        break;

    default:
        // TODO - indicate actual problem.
        [self drawErrorIndicatorInRect: rect];
        break;
    }
}

- (void) drawVerticalSection: (const KnotSection &)section
                      inRect: (NSRect)rect
{
    // Draw right stroke.
    [self drawVerticalStrokeFromSet: [mpStyle outline]
                               from: section.rightTop()
                                 to: section.rightBottom()
                           mirrored: true
                             inRect: rect
                          operation: (mHollow
                                      ? NSCompositeSourceOver
                                      : NSCompositeDestinationOut)];
    [self drawVerticalStrokeFromSet: [mpStyle fill]
                               from: section.rightTop()
                                 to: section.rightBottom()
                           mirrored: true
                             inRect: rect
                          operation: (mHollow
                                      ? NSCompositeDestinationOut
                                      : NSCompositeSourceOver)];
    // Draw left stroke.
    [self drawVerticalStrokeFromSet: [mpStyle outline]
                               from: section.leftTop()
                                 to: section.leftBottom()
                           mirrored: false
                             inRect: rect
                          operation: (mHollow
                                      ? NSCompositeSourceOver
                                      : NSCompositeDestinationOut)];
    [self drawVerticalStrokeFromSet: [mpStyle fill]
                               from: section.leftTop()
                                 to: section.leftBottom()
                           mirrored: false
                             inRect: rect
                          operation: (mHollow
                                      ? NSCompositeDestinationOut
                                      : NSCompositeSourceOver)];
}

- (void) drawSection: (const KnotSection &)section
              inRect: (NSRect)rect
        sizeInPixels: (NSSize)pixelSize
           operation: (NSCompositingOperation)op
            fraction: (CGFloat)delta
{
    NSString *key = [NSString stringWithFormat: @"%s %dx%d",
                     section.id(),
                     (int)pixelSize.width, (int)pixelSize.height];
    NSImage *pImage = [mpCache valueForKey: key];

    if (!pImage) {
        // Create the image.
        pImage = [[NSImage alloc] initWithSize: pixelSize];
        [pImage lockFocus];

        NSRect imageBounds = { NSZeroPoint, pixelSize };
        [[NSColor brownColor] set];
        [NSBezierPath fillRect: NSInsetRect(imageBounds, 1, 1)];

        // We want our origin to be in the center of the image.
        CGFloat xOffset = 0.5 * pixelSize.width;
        CGFloat yOffset = 0.5 * pixelSize.height;
        NSAffineTransform *t = [NSAffineTransform transform];
        [t translateXBy: xOffset yBy: yOffset];
        [t concat];

        NSRect drawRect = NSOffsetRect(imageBounds, -xOffset, -yOffset);

        // Draw the contents of the section.
        switch (section.type()) {

        case 'D':
            [self drawDiagonalSection: section inRect: drawRect];
            break;

        case 'H':
            [self drawHorizontalSection: section inRect: drawRect];
            break;

        case 'V':
            [self drawVerticalSection: section inRect: drawRect];
            break;

        case 'N':
            break;

        default:
            [self drawErrorIndicatorInRect: rect];
            break;
        }

        // Draw corners if needed.
        [self drawCornersForSection: section inRect: drawRect];

        [pImage unlockFocus];
        [mpCache setValue: pImage forKey: key];
    }

    [pImage drawInRect: rect
              fromRect: NSZeroRect
             operation: op
              fraction: delta];
}

- (void) flushCache
{
    [mpCache removeAllObjects];
}

@end
