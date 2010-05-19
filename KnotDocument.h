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

#ifndef KNOTDOCUMENT_H
#define KNOTDOCUMENT_H

#import <Cocoa/Cocoa.h>

#import "KnotSection.h"

#import "KnotModel.h"
@class KnotView;

@interface KnotDocument : NSDocument
{
    MutableKnotModel *model;

    IBOutlet KnotView *view;
}

@property(readonly) KnotModel *model;

- (void) setSectionType: (char)type atX: (int)x atY: (int)y;

- (void) setCornerType: (char)type atX: (int)x atY: (int)y;

@end

#endif // KNOTDOCUMENT_H
