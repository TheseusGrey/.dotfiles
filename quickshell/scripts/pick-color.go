package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net"
	"os"
)

const socketPath = "/tmp/qs-finder.sock"

func main() {
	conn, err := net.Dial("unix", socketPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to connect to finder socket: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close()

	request := map[string]interface{}{
		"items":  []string{"red", "orange", "yellow", "green", "blue", "indigo", "violet"},
		"prompt": "pick a color",
	}

	data, _ := json.Marshal(request)
	conn.Write(append(data, '\n'))

	scanner := bufio.NewScanner(conn)
	if scanner.Scan() {
		var response map[string]interface{}
		if err := json.Unmarshal(scanner.Bytes(), &response); err != nil {
			fmt.Fprintf(os.Stderr, "Failed to parse response: %v\n", err)
			os.Exit(1)
		}

		if sel, ok := response["selection"]; ok {
			fmt.Printf("Selected: %s\n", sel)
		} else {
			fmt.Println("Cancelled")
			os.Exit(1)
		}
	}
}
