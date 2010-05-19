//  Object holding the representation of a knot.
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

#ifndef KNOTMODEL_H
#define KNOTMODEL_H

#import <Cocoa/Cocoa.h>

@class KnotDocument;
#import "KnotSection.h"

@interface KnotModel : NSObject <NSCoding>
{
    // Current dimensions of the knot.  Can be negative.
    int minX, maxX;
    int minY, maxY;

    // Knot data.  Addressed as two-dimensional arrays.
    char *sectionTypes;
    char *cornerTypes;
}

@property(readonly) int minX, maxX, minY, maxY, width, height;

- (bool) hasSectionAtX: (int)x atY: (int)y;

- (KnotSection) getSectionAtX: (int)x atY: (int)y;

@end

@interface MutableKnotModel : KnotModel

- (void) setSectionType: (char)type
                    atX: (int)x
                    atY: (int)y
                    for: (KnotDocument *)owner;

- (void) setCornerType: (char)type
                   atX: (int)x
                   atY: (int)y
                   for: (KnotDocument *)owner;

@end

#endif // KNOTMODEL_H
