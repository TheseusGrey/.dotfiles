import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.services
import qs.components as Tui

// MPRIS media player — shows now-playing info and playback controls.
// Only visible when a media player is active.
//
// Visual:
//   ♫ now playing
//    Song Title That Is Lon…
//    Artist Name
//   ⏮  ⏸  ⏭   0:42/3:15
//
ColumnLayout {
    id: root
    spacing: 4

    // Get the most relevant player (prefer playing, then paused)
    readonly property var player: {
        const players = Mpris.players.values;
        if (!players || players.length === 0) return null;

        // Prefer a playing player
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing) return players[i];
        }
        // Fall back to paused
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Paused) return players[i];
        }
        return players[0];
    }

    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: hasPlayer && player.playbackState === MprisPlaybackState.Playing

    // Position must be polled — it does not update reactively
    property real currentPosition: 0.0

    Timer {
        id: positionPoller
        interval: 1000
        running: root.isPlaying
        repeat: true
        onTriggered: {
            if (root.player) root.currentPosition = root.player.position;
        }
    }

    // Sync position when player changes or starts
    onPlayerChanged: if (player) currentPosition = player.position
    onIsPlayingChanged: if (player) currentPosition = player.position

    // Only show when there's an active player
    visible: hasPlayer

    // Format seconds to M:SS
    function formatTime(seconds: real): string {
        if (seconds <= 0 || isNaN(seconds)) return "0:00";
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
    }

    // ─── Header ───
    Tui.TuiText {
        text: "♫ now playing"
        textColor: Theme.nord15  // purple accent for music
        font.bold: true
        font.pixelSize: Theme.fontSizeSmall
    }

    // ─── Track Title ───
    Tui.TuiText {
        text: {
            const title = root.player?.trackTitle ?? "";
            return title.length > 28 ? title.substring(0, 28) + "…" : title;
        }
        textColor: Theme.textBright
        font.bold: true
        Layout.fillWidth: true
    }

    // ─── Artist ───
    Tui.TuiText {
        text: {
            const artist = root.player?.trackArtist ?? "";
            return artist.length > 28 ? artist.substring(0, 28) + "…" : artist;
        }
        textColor: Theme.textMuted
        font.pixelSize: Theme.fontSizeSmall
        font.italic: true
        Layout.fillWidth: true
    }

    // ─── Controls + Position ───
    RowLayout {
        spacing: 8
        Layout.fillWidth: true

        // Previous
        Tui.TuiButton {
            text: "⏮"
            onClicked: if (root.player) root.player.previous()
        }

        // Play/Pause
        Tui.TuiButton {
            text: root.isPlaying ? "⏸" : "▶"
            onClicked: {
                if (!root.player) return;
                if (root.isPlaying) root.player.pause();
                else root.player.play();
            }
        }

        // Next
        Tui.TuiButton {
            text: "⏭"
            onClicked: if (root.player) root.player.next()
        }

        Item { Layout.fillWidth: true }

        // Position / Duration
        Tui.TuiText {
            text: {
                if (!root.player) return "";
                const pos = root.formatTime(root.currentPosition);
                const dur = root.formatTime(root.player.length);
                return `${pos}/${dur}`;
            }
            textColor: Theme.textMuted
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    // ─── Progress bar ───
    Tui.TuiProgress {
        Layout.fillWidth: true
        value: {
            if (!root.player || root.player.length <= 0) return 0;
            return root.currentPosition / root.player.length;
        }
        barLength: 20
        filledColor: Theme.nord15
    }
}
