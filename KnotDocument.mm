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

namespace
{
    const NSString *kVersionKey      = @"KnotVersion";
    const NSString *kMinXKey         = @"KnotMinX";
    const NSString *kMaxXKey         = @"KnotMaxX";
    const NSString *kMinYKey         = @"KnotMinY";
    const NSString *kMaxYKey         = @"KnotMaxY";
    const NSString *kSectionTypesKey = @"KnotSectionTypes";
    const NSString *kCornerTypesKey  = @"KnotCornerTypes";
}
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

- (NSData *) dataOfType: (NSString *)typeName error: (NSError **)outError
{
    int width = self.width;
    int height = self.height;

    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]
                                 initForWritingWithMutableData: data];

    [archiver encodeInt: 0 forKey: kVersionKey];

    [archiver encodeInt: minX forKey: kMinXKey];
    [archiver encodeInt: maxX forKey: kMaxXKey];
    [archiver encodeInt: minY forKey: kMinYKey];
    [archiver encodeInt: maxY forKey: kMaxYKey];

    [archiver encodeBytes: (uint8_t *)sectionTypes
                   length: width * height
                   forKey: kSectionTypesKey];
    [archiver encodeBytes: (uint8_t *)cornerTypes
                   length: (width+1) * (height+1)
                   forKey: kCornerTypesKey];

    [archiver finishEncoding];
    return data;
}

- (BOOL) readFromData: (NSData *)data ofType: (NSString *)typeName error: (NSError **)outError
{
    BOOL result = YES;

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc]
                                     initForReadingWithData: data];

    if ([unarchiver decodeIntForKey: kVersionKey] == 0) {
        minX = [unarchiver decodeIntForKey: kMinXKey];
        maxX = [unarchiver decodeIntForKey: kMaxXKey];
        minY = [unarchiver decodeIntForKey: kMinYKey];
        maxY = [unarchiver decodeIntForKey: kMaxYKey];

        int newWidth = self.width;
        int newHeight = self.height;
        NSUInteger length;
        const uint8_t *bytes;

        int newSectionSize = newWidth * newHeight;
        char *newSectionTypes = new char[newSectionSize];
        bytes = [unarchiver decodeBytesForKey: kSectionTypesKey
                               returnedLength: &length];
        if (length == newSectionSize) {
            memcpy(newSectionTypes, bytes, length);
        } else {
            result = NO;
        }
        delete [] sectionTypes;
        sectionTypes = newSectionTypes;

        int newCornerSize = (newWidth+1) * (newHeight+1);
        char *newCornerTypes = new char[newCornerSize];
        bytes = [unarchiver decodeBytesForKey: kCornerTypesKey
                               returnedLength: &length];
        if (length == newCornerSize) {
            memcpy(newCornerTypes, bytes, length);
        } else {
            result = NO;
        }
        delete [] cornerTypes;
        cornerTypes = newCornerTypes;

    } else {
        result = NO;
    }

    [unarchiver finishDecoding];

    if (!result) {
        if (outError != NULL) {
            *outError = [NSError errorWithDomain: NSOSStatusErrorDomain code: ioErr userInfo: NULL];
	}
    }

    return result;
}

@end
