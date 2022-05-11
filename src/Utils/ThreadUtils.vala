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
delegate void Notejot.WorkerFunc ();
delegate G Notejot.ThreadFunc<G> () throws Error;

[Compact (opaque = true)]
class Notejot.Worker {
    WorkerFunc func;

    public Worker (owned WorkerFunc func) {
        this.func = (owned) func;
    }

    public void run () {
        func ();
    }
}

namespace Notejot.ThreadUtils {
    Once<ThreadPool<Worker>> _once;

    unowned ThreadPool<Worker> _get_thread_pool () throws ThreadError {
        return _once.once (() => {
            var tp = new ThreadPool<Worker>.with_owned_data (worker => worker.run (), 1, false);
            return tp;
        });
    }

    async G run_in_thread<G> (owned ThreadFunc<G> func) throws Error {
        unowned var thread_pool = _get_thread_pool ();

        G result = null;
        Error? error = null;

        thread_pool.add (new Worker (() => {
            try {
                result = func ();
            } catch (Error err) {
                error = err;
            }

            Idle.add (run_in_thread.callback);
        }));

        yield;

        if (error != null)
            throw error;

        return result;
    }
}
