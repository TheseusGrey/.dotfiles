pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// FinderServer — Unix socket server for custom finder requests.
//
// Protocol (newline-delimited JSON):
//
// Client → QS (request):
//   {"items":["Option A","Option B","Option C"],"prompt":"Pick one"}
//
// QS → Client (response):
//   {"selection":"Option B"}    — user selected an item
//   {"cancelled":true}          — user pressed Escape / closed panel
//
// Usage from bash:
//   echo '{"items":["foo","bar","baz"],"prompt":"choose"}' | socat - UNIX-CONNECT:/tmp/qs-finder.sock
//
// The server accepts one connection at a time. If a new connection arrives while
// a selection is pending, the old one is cancelled and the new one takes over.
//
Singleton {
    id: root

    // ─── Public API (consumed by Finder.qml) ─────────────────────────
    property var customItems: []       // string[] of item names
    property string customPrompt: ""   // optional prompt text
    property bool hasPendingRequest: false

    // Called by Finder when user makes a selection
    function resolveSelection(selection) {
        if (!root.hasPendingRequest) return;
        sendResponse(JSON.stringify({ selection: selection }) + "\n");
        cleanup();
    }

    // Called by Finder when user cancels (Escape)
    function resolveCancelled() {
        if (!root.hasPendingRequest) return;
        sendResponse(JSON.stringify({ cancelled: true }) + "\n");
        cleanup();
    }

    // ─── Signal emitted when a new custom request arrives ────────────
    signal customRequestReceived()

    // ─── Internal socket management ──────────────────────────────────
    property var activeSocket: null

    function sendResponse(text) {
        if (root.activeSocket && root.activeSocket.connected) {
            root.activeSocket.write(text);
            root.activeSocket.flush();
        }
    }

    function cleanup() {
        root.hasPendingRequest = false;
        root.customItems = [];
        root.customPrompt = "";
        // Don't forcibly close — let the client read the response and disconnect.
        // The socket will be cleaned up when the client disconnects.
        root.activeSocket = null;
    }

    // Cancel any pending request (e.g. new connection supersedes old)
    function cancelPending() {
        if (root.hasPendingRequest) {
            sendResponse(JSON.stringify({ cancelled: true }) + "\n");
            root.hasPendingRequest = false;
            root.customItems = [];
            root.customPrompt = "";
            root.activeSocket = null;
        }
    }

    // ─── Socket server ───────────────────────────────────────────────
    SocketServer {
        id: server
        active: true
        path: "/tmp/qs-finder.sock"

        handler: Component {
            Socket {
                id: clientSocket

                property string buffer: ""

                parser: SplitParser {
                    onRead: data => {
                        // Accumulate data (in case JSON spans multiple reads)
                        clientSocket.buffer += data;

                        // Try to parse as JSON
                        try {
                            const request = JSON.parse(clientSocket.buffer);
                            clientSocket.buffer = "";
                            root.handleRequest(request, clientSocket);
                        } catch (e) {
                            // Not valid JSON yet — might be partial, wait for more data
                            // If buffer is getting too large, reject
                            if (clientSocket.buffer.length > 65536) {
                                clientSocket.write(JSON.stringify({ error: "request too large" }) + "\n");
                                clientSocket.flush();
                                clientSocket.buffer = "";
                            }
                        }
                    }
                }

                onConnectedChanged: {
                    if (!connected) {
                        // Client disconnected before we could respond
                        if (root.activeSocket === clientSocket && root.hasPendingRequest) {
                            root.hasPendingRequest = false;
                            root.customItems = [];
                            root.customPrompt = "";
                            root.activeSocket = null;
                            // Close the finder panel since the requester is gone
                            PanelState.closeRight();
                        }
                    }
                }
            }
        }
    }

    // ─── Request handler ─────────────────────────────────────────────
    function handleRequest(request, socket) {
        // Validate request
        if (!request.items || !Array.isArray(request.items) || request.items.length === 0) {
            socket.write(JSON.stringify({ error: "items array required and must be non-empty" }) + "\n");
            socket.flush();
            return;
        }

        // Cancel any existing pending request
        cancelPending();

        // Store the new request
        root.activeSocket = socket;
        root.customItems = request.items;
        root.customPrompt = request.prompt || "";
        root.hasPendingRequest = true;

        // Open the finder in custom mode
        PanelState.openRight("finder");
        root.customRequestReceived();
    }
}
