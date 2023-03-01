/*
* Copyright (C) 2017-2021 Lains
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
[GtkTemplate (ui = "/io/github/lainsce/Notejot/notebookmainrowcontent.ui")]
public class Notejot.NotebookMainRowContent : He.Bin {
    public signal void clicked ();
    public NotebookViewModel? notebooks {get; set;}

    [GtkChild]
    public unowned He.Chip chip;

    Binding? text_binding;

    Notebook? _notebook;
    public Notebook? notebook {
        get { return _notebook; }
        set {
            if (value == _notebook)
                return;

            text_binding?.unbind ();

            _notebook = value;

            text_binding = _notebook?.bind_property ("title", chip, "label", SYNC_CREATE);
        }
    }

    construct {
    }
}