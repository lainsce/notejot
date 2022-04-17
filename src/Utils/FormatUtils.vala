/*
* Copyright (C) 2017-2022 Lains
*
* This program is free software; you can redistribute it &&/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
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
namespace Notejot {
    public enum Format {
        BOLD,
        ITALIC,
        UNDERLINE,
        STRIKETHROUGH
    }

    public struct FormatBlock {
        public int start;
        public int end;
        public Format format;
    }

    public string format_to_string(Format fmt) {
        switch (fmt) {
            case Format.BOLD:
                return "**";
            case Format.ITALIC:
                return "*";
            case Format.UNDERLINE:
                return "_";
            case Format.STRIKETHROUGH:
                return "~";
            default:
                assert_not_reached();
        }
    }

    public Format string_to_format(string wrap) {
        switch (wrap) {
            case "**":
                return Format.BOLD;
            case "*":
                return Format.ITALIC;
            case "_":
                return Format.UNDERLINE;
            case "~":
                return Format.STRIKETHROUGH;
            default:
                assert_not_reached();
        }
    }
}
