package main

import (
	"bufio"
	"fmt"
	"net/http"
	"sync"
	"time"
)

const (
	numConnections = 10000
	sseURL         = "http://localhost:8081/clock" // replace with your SSE endpoint
)

func connectToSSE(id int, wg *sync.WaitGroup) {
	defer wg.Done()

	req, err := http.NewRequest("GET", sseURL, nil)
	if err != nil {
		fmt.Printf("Goroutine %d: Failed to create request: %v\n", id, err)
		return
	}
	req.Header.Set("Accept", "text/event-stream")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Printf("Goroutine %d: Failed to connect: %v\n", id, err)
		return
	}
	defer resp.Body.Close()

	scanner := bufio.NewScanner(resp.Body)
	for scanner.Scan() {
		fmt.Printf("Goroutine %d: %s\n", id, scanner.Text())
	}
	if err := scanner.Err(); err != nil {
		fmt.Printf("Goroutine %d: Read error: %v\n", id, err)
	}
}

func main() {
	fmt.Printf("Go loadtester on localhost:8081/clock endpoint\n- doing %d clients in parallel with 1ms delay between each\n", numConnections)
	var wg sync.WaitGroup
	for i := 0; i < numConnections; i++ {
		wg.Add(1)
		go connectToSSE(i, &wg)
		time.Sleep(1 * time.Millisecond) // slight delay to avoid overwhelming the server
	}
	fmt.Println("Started all connections.")
	wg.Wait()
}
