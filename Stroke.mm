//  A single primitive stroke, represented by an NSImage.
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

#import "Stroke.h"

@implementation Stroke

- (id) initWithName: (NSString *)name
{
    self = [super init];
    if (self) {
        // Load the (PDF) image.
        NSBundle *bundle = [NSBundle bundleWithIdentifier: @"de.earrame.Beltane"];
        NSString *path = [bundle pathForResource: name ofType: @"pdf"];

        mpImage = [[NSImage alloc] initWithContentsOfFile: path];
    }
    return self;
}

- (NSImage *) image
{
    return mpImage;
}

@end
