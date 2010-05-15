//  Document representation of a knot.
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

#import "KnotDocument.h"

#include <algorithm>
#include <cstring>
using namespace ::std;

@implementation KnotDocument

- (id)init
{
    self = [super init];
    if (self) {
        [self setHasUndoManager: NO];

        // Start off with a single default section.
        minX = maxX = minY = maxY = 0;

        sectionTypes = new char[1*1];
        memset(sectionTypes, 'D', 1*1);
        cornerTypes  = new char[2*2];
        memset(cornerTypes, 'D', 2*2);
    }
    return self;
}

// Manipulating knot data.

@synthesize minX, maxX, minY, maxY;

- (int) width
{
    return maxX - minX + 1;
}

- (int) height
{
    return maxY - minY + 1;
}

- (bool) hasSectionAtX: (int)x atY: (int)y
{
    return ! (x < minX || x > maxX || y < minY || y > maxY);
}

- (KnotSection) getSectionAtX: (int)x atY: (int)y
{
    if ([self hasSectionAtX: x atY: y]) {
        int dx = x - minX;
        int dy = y - minY;
        return KnotSection(sectionTypes[dy * self.width + dx],
                           cornerTypes[(dy+0) * (self.width+1) + dx+0],
                           cornerTypes[(dy+0) * (self.width+1) + dx+1],
                           cornerTypes[(dy+1) * (self.width+1) + dx+0],
                           cornerTypes[(dy+1) * (self.width+1) + dx+1]);
    }

    // Outside the current bounds - return a dummy section.
    return KnotSection('N', 'N', 'N', 'N', 'N');
}

- (void) growLeft: (int)l right: (int)r top: (int)t bottom: (int)b
{
    int width = self.width;
    int height = self.height;

    int newWidth = width + l + r;
    int newHeight = height + t + b;

    int newSectionSize = newWidth * newHeight;
    char *newSectionTypes = new char[newSectionSize];
    memset(newSectionTypes, 'D', newSectionSize);

    int newCornerSize = (newWidth+1) * (newHeight+1);
    char *newCornerTypes  = new char[newCornerSize];
    memset(newCornerTypes, 'D', newCornerSize);

    for (int i = 0; i < height; ++i) {
        memcpy(newSectionTypes + (i+t)*newWidth + l,
               sectionTypes + i*width,
               width);
    }
    for (int i = 0; i <= height; ++i) {
        memcpy(newCornerTypes + (i+t)*(newWidth+1) + l,
               cornerTypes + i*(width+1),
               width+1);
    }

    minX -= l;
    maxX += r;
    minY -= t;
    maxY += b;

    delete [] sectionTypes;
    sectionTypes = newSectionTypes;
    delete [] cornerTypes;
    cornerTypes = newCornerTypes;
}

- (void) setSectionType: (char)type atX: (int)x atY: (int)y;
{
    if (x < minX || x > maxX || y < minY || y > maxY) {
        [self growLeft: max(0, minX - x)
                 right: max(0, x - maxX)
                   top: max(0, minY - y)
                bottom: max(0, y - maxY)];
    }

    int dx = x - minX;
    int dy = y - minY;
    sectionTypes[dy * self.width + dx] = type;

    [self updateChangeCount: NSChangeDone];
}

- (void) setCornerType: (char)type atX: (int)x atY: (int)y;
{
    if (x < minX || x > maxX+1 || y < minY || y > maxY+1) {
        [self growLeft: max(0, minX - x)
                 right: max(0, x - maxX - 1)
                   top: max(0, minY - y)
                bottom: max(0, y - maxY - 1)];
    }

    int dx = x - minX;
    int dy = y - minY;
    cornerTypes[dy * (self.width+1) + dx] = type;

    [self updateChangeCount: NSChangeDone];
}

// Cocoa document management.

- (NSString *) windowNibName
{
    return @"KnotDocument";
}

- (void) windowControllerDidLoadNib: (NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (BOOL) writeToURL: (NSURL *)absoluteURL ofType: (NSString *)typeName error: (NSError **)outError
{
    int width = self.width;
    int height = self.height;

    // TODO - use NSKeyedArchiver
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt: minX],   @"minX",
                          [NSNumber numberWithInt: maxX],   @"maxX",
                          [NSNumber numberWithInt: minY],   @"minY",
                          [NSNumber numberWithInt: maxY],   @"maxY",
                          [NSData dataWithBytesNoCopy: sectionTypes
                                               length: width * height
                                         freeWhenDone: NO], @"sectionTypes",
                          [NSData dataWithBytesNoCopy: cornerTypes
                                               length: (width+1) * (height+1)
                                         freeWhenDone: NO], @"cornerTypes",
                          NULL];

    BOOL result = [dict writeToURL: absoluteURL atomically: YES];

    if (!result) {
        if (outError != NULL) {
            *outError = [NSError errorWithDomain: NSOSStatusErrorDomain code: ioErr userInfo: NULL];
	}
    }

    return result;
}

- (BOOL) readFromURL: (NSURL *)absoluteURL ofType: (NSString *)typeName error: (NSError **)outError
{
    BOOL result = YES;

    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL: absoluteURL];
    if (dict != nil) {
        minX = [[dict objectForKey: @"minX"] intValue];
        maxX = [[dict objectForKey: @"maxX"] intValue];
        minY = [[dict objectForKey: @"minY"] intValue];
        maxY = [[dict objectForKey: @"maxY"] intValue];

        int newWidth = self.width;
        int newHeight = self.height;

        int newSectionSize = newWidth * newHeight;
        char *newSectionTypes = new char[newSectionSize];
        [[dict objectForKey: @"sectionTypes"] getBytes: newSectionTypes
                                                length: newSectionSize];

        int newCornerSize = (newWidth+1) * (newHeight+1);
        char *newCornerTypes  = new char[newCornerSize];
        [[dict objectForKey: @"cornerTypes"] getBytes: newCornerTypes
                                                length: newCornerSize];

        delete [] sectionTypes;
        sectionTypes = newSectionTypes;
        delete [] cornerTypes;
        cornerTypes = newCornerTypes;

    } else {
        result = NO;
    }

    if (!result) {
        if (outError != NULL) {
            *outError = [NSError errorWithDomain: NSOSStatusErrorDomain code: ioErr userInfo: NULL];
	}
    }

    return result;
}

@end
