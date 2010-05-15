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

// Traditionally, Celtic knotwork is drawn on a diagonal grid
// overlaid with straight lines and circles.  We use a simpler
// method devised by Andy Sloss, which divides the knot
// into sections at every other grid point.  Each section can be
// uniquely described by the directions in which the knot passes
// through the section's corners, plus the directions the two lines
// take in the interior of the section.
// There are three possible directions (diagonal, horizontal and
// vertical), so there are 3^5 = 243 basic sections.  The horizontal
// and vertical sections can be split in half for closing up the edges
// of a knot, yielding another 36 shapes.  These are represented
// as a section with two corners that have "no" direction.
//
// Because of symmetries, the 279 different sections can be drawn
// using only 10 basic strokes.

#ifndef KNOTSECTION_H
#define KNOTSECTION_H

#include <cstring>

class KnotSection
{
public:
    KnotSection(char type, char lt, char rt, char lb, char rb)
    {
        mId[TYPE] = type;
        mId[LT]   = lt;
        mId[RT]   = rt;
        mId[LB]   = lb;
        mId[RB]   = rb;
        mId[EOS]  = '\0';
    }

    char type(void) const        { return mId[TYPE]; }
    char leftTop(void) const     { return mId[LT];   }
    char rightTop(void) const    { return mId[RT];   }
    char leftBottom(void) const  { return mId[LB];   }
    char rightBottom(void) const { return mId[RB];   }

    const char *id(void) const   { return mId;       }

    bool
    operator <(const KnotSection &section) const
    {
        return ::std::memcmp(mId, section.mId, SIZE) < 0;
    }

private:
    enum { TYPE, LT, RT, LB, RB, EOS, SIZE };

    // Data members.
    char mId[SIZE];
};

#endif
