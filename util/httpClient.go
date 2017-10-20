package util

import (
	"bytes"
	"log"
	"net/http"
	"time"
)

type HttpClient struct {
}

////////////
// FUNCTIONS
////////////
func GetMethod(url string, data *bytes.Buffer) *http.Response {
	return requestMethod(url, http.MethodGet, data)
}
func PostMethod(url string, data *bytes.Buffer) *http.Response {
	return requestMethod(url, http.MethodPost, data)
}
func PutMethod(url string, data *bytes.Buffer) *http.Response {
	return requestMethod(url, http.MethodPut, data)
}
func requestMethod(url string, method string, data *bytes.Buffer) *http.Response {
	client := &http.Client{Timeout: 15 * time.Second}
	log.Printf("Request with %s method to %s", method, url)
	req, err := http.NewRequest(method, url, data)
	if err != nil {
		// handle error
		log.Fatal(err)
	}
	res, err := client.Do(req)
	if err != nil {
		// handle error
		log.Fatal(err)
	}
	return res
}
