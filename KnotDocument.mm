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

#import "KnotModel.h"
#import "KnotView.h"

@implementation KnotDocument

@synthesize model;

- (id)init
{
    self = [super init];
    if (self) {
        [self setHasUndoManager: NO];

        model = [[KnotModel alloc] init];
    }
    return self;
}

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
    return [NSKeyedArchiver archivedDataWithRootObject: model];
}

- (BOOL) readFromData: (NSData *)data ofType: (NSString *)typeName error: (NSError **)outError
{
    KnotModel *newModel = [NSKeyedUnarchiver unarchiveObjectWithData: data];

    if (newModel != nil) {
        model = newModel;
        return YES;
    }

    if (outError != NULL) {
        *outError = [NSError errorWithDomain: NSOSStatusErrorDomain code: ioErr userInfo: NULL];
    }
    return NO;
}

@end
