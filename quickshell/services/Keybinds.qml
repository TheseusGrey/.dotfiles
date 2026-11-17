pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shared, on-demand cache of Hyprland keybinds.
//
// The finder, the keybind cheat-sheet and the panel-key collision check all
// need the same `hyprctl -j binds` dump. Previously each one spawned its own
// copy at shell startup. Now a single process runs once and everyone reads
// the parsed result from here.
Singleton {
    id: root

    property var binds: []
    property bool loaded: false
    property bool requested: false

    function request() {
        if (root.requested) return;
        root.requested = true;
        proc.running = true;
    }

    Process {
        id: proc
        command: ["hyprctl", "-j", "binds"]
        running: false

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => { proc.buffer += data + "\n"; }
        }

        onRunningChanged: {
            if (running) return;
            let parsed = [];
            try {
                parsed = JSON.parse(proc.buffer) || [];
            } catch (e) {
                // No Hyprland session (or a transient failure): leave the
                // cache empty. Consumers render an empty/loading state.
            }
            proc.buffer = "";
            root.binds = parsed;
            root.loaded = true;
        }
    }
}
