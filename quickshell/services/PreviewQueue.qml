pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// PreviewQueue derives wallpaper accent bars lazily. Requests are deduplicated
// against an in-memory cache and run through three matugen workers at a time so
// opening the theme panel does not spawn one process per wallpaper.
Singleton {
    id: root

    readonly property string qsh: Quickshell.env("HOME") + "/.local/bin/qsh"

    // file name -> [bg, primary, secondary, tertiary]
    property var cache: ({})
    property var queue: []

    signal previewReady(string file, var colors)

    function cached(file) {
        return cache[file];
    }

    function request(file) {
        if (!file) return;
        if (cache[file] !== undefined) return;
        if (queue.indexOf(file) !== -1) return;
        queue.push(file);
        pump();
    }

    function cancelAll() {
        queue = [];
        const workers = [worker1, worker2, worker3];
        for (let i = 0; i < workers.length; i++) {
            if (workers[i].running) workers[i].running = false;
        }
    }

    function pump() {
        const workers = [worker1, worker2, worker3];
        for (let i = 0; i < workers.length && queue.length > 0; i++) {
            const w = workers[i];
            if (w.running) continue;
            const file = queue.shift();
            w.currentFile = file;
            w.buffer = "";
            w.command = [root.qsh, "accent", file];
            w.running = true;
        }
    }

    function finish(w) {
        const file = w.currentFile;
        const parts = w.buffer.trim().split(/\s+/);
        if (file !== "" && parts.length >= 4) {
            cache[file] = parts.slice(0, 4);
            root.previewReady(file, cache[file]);
        }
        pump();
    }

    Process {
        id: worker1
        property string currentFile: ""
        property string buffer: ""
        running: false
        stdout: SplitParser {
            onRead: data => { worker1.buffer += data + "\n"; }
        }
        onExited: root.finish(worker1)
    }

    Process {
        id: worker2
        property string currentFile: ""
        property string buffer: ""
        running: false
        stdout: SplitParser {
            onRead: data => { worker2.buffer += data + "\n"; }
        }
        onExited: root.finish(worker2)
    }

    Process {
        id: worker3
        property string currentFile: ""
        property string buffer: ""
        running: false
        stdout: SplitParser {
            onRead: data => { worker3.buffer += data + "\n"; }
        }
        onExited: root.finish(worker3)
    }
}
