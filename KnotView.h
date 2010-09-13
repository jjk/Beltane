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

#ifndef KNOTVIEW_H
#define KNOTVIEW_H

#import <Cocoa/Cocoa.h>

@class KnotDocument;
@class KnotEngine;
#include "KnotSection.h"
@class KnotStyle;

enum // Tiling flags
{
    HORIZONTAL = (1 << 0),
    VERTICAL   = (1 << 1)
};
enum // Knot styles
{
    BROAD  = (1 << 0),
    HOLLOW = (1 << 1)
};

@interface KnotView : NSView
{
    IBOutlet KnotDocument *document;

    int tilingMode;
    KnotStyle *style;
    bool hollow;
    CGFloat sectionSize;
    KnotEngine *engine;

    int selX, selY;
    bool selCorner;
}

@property CGFloat sectionSize;

- (IBAction) setTilingMode: (id)sender;
- (IBAction) setStyle: (id)sender;
- (IBAction) zoom: (id)sender;
- (IBAction) centerAndFit: (id)sender;

@end

#endif // KNOTVIEW_H
