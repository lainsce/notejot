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

    unowned ThreadPool<Worker> _get_thread_pool () {
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
