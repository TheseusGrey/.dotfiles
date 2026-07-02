package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net"
	"os"
)

// Example: using the quickshell finder socket from Go.
//
// This is equivalent to `just pick-color` but without the coproc/socat
// complexity — Go's net.Dial gives a full-duplex unix socket natively.
//
// Usage:
//   go run pick-color.go
//
// Build:
//   go build -o pick-color pick-color.go

const socketPath = "/tmp/qs-finder.sock"

func main() {
	conn, err := net.Dial("unix", socketPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to connect: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close()

	request := map[string]interface{}{
		"items":  []string{"red", "green", "blue", "yellow", "purple", "orange"},
		"prompt": "pick a color",
	}

	data, _ := json.Marshal(request)
	data = append(data, '\n')

	if _, err := conn.Write(data); err != nil {
		fmt.Fprintf(os.Stderr, "failed to write: %v\n", err)
		os.Exit(1)
	}

	scanner := bufio.NewScanner(conn)
	if !scanner.Scan() {
		fmt.Fprintf(os.Stderr, "no response received\n")
		os.Exit(1)
	}

	var response map[string]interface{}
	if err := json.Unmarshal(scanner.Bytes(), &response); err != nil {
		fmt.Fprintf(os.Stderr, "invalid response: %v\n", err)
		os.Exit(1)
	}

	if selection, ok := response["selection"].(string); ok {
		fmt.Printf("You picked: %s\n", selection)
	} else {
		fmt.Println("Cancelled")
	}
}
