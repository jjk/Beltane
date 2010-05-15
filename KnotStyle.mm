//  Drawing style for a knot, combining fill and outline strokes.
//
//  Copyright © 2009,2010  Jens Kilian
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

#import "KnotStyle.h"

#import "StrokeSet.h"

@implementation KnotStyle

- (id) initWithName: (NSString *)name
{
    self = [super init];
    if (self) {
        mpOutline = [[StrokeSet alloc] initWithStyle: name andType: @"outline"];
        mpFill = [[StrokeSet alloc] initWithStyle: name andType: @"fill"];
    }
    return self;
}

- (StrokeSet *) outline
{
    return mpOutline;
}

- (StrokeSet *) fill
{
    return mpFill;
}

@end
