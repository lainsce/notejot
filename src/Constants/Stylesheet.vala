/*
* Copyright (c) 2017 Lains
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

namespace Notejot.Stylesheet {
    public const string NOTE = """
        @define-color textColorPrimary #666;

        .notejot-toolbar {
            background: transparent;
            border-bottom-color: transparent;
            box-shadow: inset 0px 1px 1px -2px white;
        }

        .notejot-note {
            font-size: 11px;
        }

        .notejot-note:selected {
            background-color: #95a3ab;
        }


    """;
}
