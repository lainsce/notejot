/*
* Copyright (c) 2017-2022 Lains
*
* This program is free software; you can redistribute it and/or
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
*
*/
public class Notejot.Application : Adw.Application {
    private const GLib.ActionEntry app_entries[] = {
        { "quit", quit },
    };

    public Application () {
        Object (application_id: Config.APP_ID);
    }
    public static int main (string[] args) {
        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.textdomain (Config.GETTEXT_PACKAGE);

        var app = new Notejot.Application ();
        return app.run (args);
    }
    protected override void startup () {
        resource_base_path = "/io/github/lainsce/Notejot";

        base.startup ();

        add_action_entries (app_entries, this);

        typeof (NoteListView).ensure ();
        typeof (NoteGridView).ensure ();
        typeof (NoteContentView).ensure ();

        var repo = new NoteRepository ();
        var view_model = new NoteViewModel (repo);

        typeof (NotebookListView).ensure ();
        typeof (NotebookMainListView).ensure ();
        typeof (NotebookMoveListView).ensure ();

        var nbrepo = new NotebookRepository ();
        var nbview_model = new NotebookViewModel (nbrepo);

        typeof (TrashListView).ensure ();
        typeof (TrashContentView).ensure ();

        var trepo = new TrashRepository ();
        var tview_model = new TrashViewModel (trepo);

        new MainWindow (this, view_model, tview_model, nbview_model);
    }
    protected override void activate () {
        active_window?.present ();
    }
}
