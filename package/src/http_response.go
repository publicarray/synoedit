// HTML user interface for dnscrypt-proxy
// Copyright Sebastian Schmidt
// Licence MIT
package main

import (
	"fmt"
	"os"
	"strings"
)

type HttpResponse struct {
	statusCode  int
	Status      string
	ContentType string
}

// Generate http/1.1 response
func NewHttpResponse(statusCode int, statusMessage string) *HttpResponse {
	httpResponse := HttpResponse{
		statusCode:  statusCode,
		Status:      "Status: " + fmt.Sprintf("%v", statusCode) + " " + statusMessage + "\n",
		ContentType: "Content-Type: text/html; charset=utf-8\n",
	}
	return &httpResponse
}

// Print http response to stdout
func (httpResponse *HttpResponse) print(str ...string) {
	fmt.Println(httpResponse.Status + httpResponse.ContentType)
	fmt.Println(strings.Join(str, " "))
	os.Exit(0)
}

// --- //

// Exit program with a HTTP Internal Error status code and a message (dump and die)
func logError(str ...string) {
	NewHttpResponse(500, "Internal server error").print(strings.Join(str, " "))
	os.Exit(0)
}

// Exit program with a HTTP Unauthorized status code and a message (dump and die)
func logUnauthorised(str ...string) {
	NewHttpResponse(401, "Unauthorized").print(strings.Join(str, " "))
	os.Exit(0)
}

// Exit program with a HTTP Not Found status code
func notFound(str ...string) {
	NewHttpResponse(404, "Not Found").print(strings.Join(str, " "))
	os.Exit(0)
}
