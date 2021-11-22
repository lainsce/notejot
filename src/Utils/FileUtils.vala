namespace Notejot.FileUtils {
    async bool create_text_file (string filename, string contents, Cancellable? cancellable = null) throws Error {
        return yield ThreadUtils.run_in_thread<bool> (() => {
            var dir_path = Path.build_filename (Environment.get_user_data_dir (), "/io.github.lainsce.Notejot/");

            if (DirUtils.create_with_parents (dir_path, 0755) != 0) {
                throw new Error (FileError.quark (), GLib.FileUtils.error_from_errno (errno), "%s", strerror (errno));
            }

            var file_path = Path.build_filename (dir_path, filename);
            GLib.FileUtils.set_contents (file_path, contents);

            return true;
        });
    }

    async string? read_text_file (string filename, Cancellable? cancellable = null) throws Error {
        return yield ThreadUtils.run_in_thread<string?> (() => {
            var file_path = Path.build_filename (Environment.get_user_data_dir (), "/io.github.lainsce.Notejot/", filename);

            string contents = "";

            try {
                GLib.FileUtils.get_contents (file_path, out contents);
            } catch (Error err) {
                if (err is FileError.NOENT)
                    return null;

                throw err;
            }

            return contents;
        });
    }
}
