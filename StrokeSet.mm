//  A StrokeSet contains the 10 basic strokes from which knots are built,
//  plus an additional stroke used in filling in corners.
//
//  Copyright © 2003-2010  Jens Kilian
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

#import "StrokeSet.h"

#import "Stroke.h"

namespace
{
    static const NSString *kpShape[Strokes::NumStrokes] =
    {
        @"DDD", @"DHD", @"DHH", @"DHV",
        @"HDD", @"HDH", @"HDV", @"HHH", @"HHV", @"HVV",
        @"corner"
    };
}

@implementation StrokeSet

- (id) initWithStyle: (NSString *)style andType: (NSString *)type
{
    self = [super init];
    if (self) {
        NSString *prefix = [NSString stringWithFormat: @"%@_%@_", style, type];

        for (int i = 0; i < Strokes::NumStrokes; ++i) {
            NSString *name = [prefix stringByAppendingString: kpShape[i]];
            mpStrokes[i] = [[Stroke alloc] initWithName: name];
        }
    }
    return self;
}

- (Stroke *) strokeAt: (unsigned int)index;
{
    return mpStrokes[index];
}

@end
