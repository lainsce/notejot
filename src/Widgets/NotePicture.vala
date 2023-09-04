/*
 * Copyright (C) 2017-2022 Lains
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
sealed class Notejot.NotePicture : Gtk.Widget {
    private Gdk.Texture _texture = null;

    private string _file = null;
    public string file {
        get { return this._file; }
        set {
            if (this._file == value?.strip ()) {
                return;
            }

            this._file = value?.strip ();

            if (value != null) {
                try {
                    this._texture = Gdk.Texture.from_filename (value?.strip ());
                } catch (Error e) {
                    // w/e lol
                }

                this.queue_draw ();
                this.queue_resize ();
            }
        }
    }

    private bool _rounded;
    public bool rounded {
        get { return _rounded; }
        set { 
            _rounded = value;
        }
    }

    ~NotePicture () {
        this._texture = null;
        this._file = null;
    }

    protected override Gtk.SizeRequestMode get_request_mode () {
        return WIDTH_FOR_HEIGHT;
    }

    protected override void snapshot (Gtk.Snapshot snapshot) {
        if (this._texture == null) {
            return;
        }

        var ideal_width = this.get_width ();
        var ideal_height = this.get_height ();

        var ideal_ratio = ideal_width / ideal_height;

        var width = this._texture.get_width ();
        var height = this._texture.get_height ();

        var ratio = width / float.parse ("%d".printf (height));

        if (ratio > ideal_ratio) {
            var new_width = int.parse ("%f".printf (ideal_ratio * height));
            var offset = (width - new_width) / 2;
            var resize_x = 0;
            var resize_y = offset;
            var resize_width = width - offset;
            var resize_height = height;
            this.notify["rounded"].connect (() => {
                if (rounded) {
                    Gsk.RoundedRect rrect = {};
                    rrect.init_from_rect ({{ resize_x, resize_y }, { resize_width, resize_height }}, 12);
                    snapshot.push_rounded_clip (rrect);
                    snapshot.pop ();
                } else {
                    var rect = Graphene.Rect.zero ();
                    rect.init (resize_x, resize_y, resize_width, resize_height);
                    snapshot.push_clip (rect);
                    snapshot.scale (offset, height);
                    snapshot.pop ();
                }
            });
        } else {
            var new_height = int.parse ("%f".printf (width / ideal_ratio));
            var offset = (height - new_height) / 2;
            var resize_x = 0;
            var resize_y = offset;
            var resize_width = width;
            var resize_height = height - offset;
            this.notify["rounded"].connect (() => {
                if (rounded) {
                    Gsk.RoundedRect rrect = {};
                    rrect.init_from_rect ({{ resize_x, resize_y }, { resize_width, resize_height }}, 12);
                    snapshot.push_rounded_clip (rrect);
                    snapshot.pop ();
                } else {
                    var rect = Graphene.Rect.zero ();
                    rect.init (resize_x, resize_y, resize_width, resize_height);
                    snapshot.push_clip (rect);
                    snapshot.scale (offset, height);
                    snapshot.pop ();
                }
            });
        }
        this._texture.snapshot (snapshot, ideal_width, ideal_height);
    }

    public void clear_image () {
        this._texture = null;

        this.queue_draw ();
        this.queue_resize ();
    }
}
