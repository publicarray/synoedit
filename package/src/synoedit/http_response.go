/*
SynoEdit - A Synology package and HTML user interface to edit files
Copyright (C) 2018 Sebastian Schmidt

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

// HTTPResponse contains a typical HTTP response with status code, message and a content type header
type HTTPResponse struct {
	statusCode  int
	Status      string
	Server      string
	ContentType string
}

// JSONResponse for the JavaScript front-end
//  DSM is modifying the return status codes and contents intended for detecting
//  different messages in the JavaScript front-end
type JSONResponse struct {
	// 0 ok, 1 Error
	Status  int    `json:"status"`
	Message string `json:"message"`
}

// NewHTTPResponse generates a http/1.1 response
func NewHTTPResponse(statusCode int, statusMessage string) *HTTPResponse {
	HTTPResponse := HTTPResponse{
		statusCode:  statusCode,
		Status:      "Status: " + fmt.Sprintf("%v", statusCode) + " " + statusMessage + "\r\n",
		Server:      "Server: synoedit " + AppVersion + "\r\n",
		ContentType: "Content-Type: text/plain; charset=utf-8\r\n",
	}
	return &HTTPResponse
}

// Print http response to stdout
func (HTTPResponse *HTTPResponse) print(str ...string) {
	fmt.Print(HTTPResponse.Status + HTTPResponse.ContentType + HTTPResponse.Server + "\r\n")
	fmt.Print(strings.Join(str, " "))
	os.Exit(0)
}

// --- //

// Exit program with a HTTP Internal Error status code and a message (dump and die)
func logError(str ...string) {
	jsonMessage(1, strings.Join(str, " "))
}

// Exit program with a HTTP Unauthorized status code and a message (dump and die)
func logUnauthorised(str ...string) {
	NewHTTPResponse(401, "Unauthorized").print(strings.Join(str, " "))
	os.Exit(0)
}

// Exit program with a HTTP Not Found status code
func notFound(str ...string) {
	NewHTTPResponse(404, "Not Found").print(strings.Join(str, " "))
	os.Exit(0)
}

// Return HTML with OK status message
func okHTML(str ...string) {
	okPlainRes := NewHTTPResponse(200, "OK")
	okPlainRes.ContentType = "Content-Type: text/html; charset=utf-8;\r\n"
	okPlainRes.print(strings.Join(str, " "))
	NewHTTPResponse(200, "OK").print(strings.Join(str, " "))
	os.Exit(0)
}

// Return plain text with OK status message
// func okPlain(str ...string) {
// 	NewHTTPResponse(200, "OK").print(strings.Join(str, " "))
// 	os.Exit(0)
// }

/**
 * Send a JSON object as HTTP/1.1 in stdout
 * @param  int status       The status code, 0=success 1=error
 * @param  strings message  The message to send
 */
func jsonMessage(status int, message ...string) {
	okJSONRes := NewHTTPResponse(200, "OK")
	// RSM 1.2 Doesn't allow 'application/json' Content-Type to pass through!
	// okJsonRes.ContentType = "application/json;\r\n"
	jsonObj := &JSONResponse{
		Status:  status,
		Message: strings.Join(message, " "),
	}
	jsonBytes, err := json.Marshal(jsonObj)
	if err != nil {
		panic(err)
	}
	okJSONRes.print(string(jsonBytes))
	os.Exit(0)
}
