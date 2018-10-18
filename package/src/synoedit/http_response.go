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
	"fmt"
	"os"
	"strings"
)

// HTTPResponse contains a typical HTTP response with status code, message and a content type header
type HTTPResponse struct {
	statusCode  int
	Status      string
	ContentType string
}

// NewHTTPResponse generates a http/1.1 response
func NewHTTPResponse(statusCode int, statusMessage string) *HTTPResponse {
	HTTPResponse := HTTPResponse{
		statusCode:  statusCode,
		Status:      "Status: " + fmt.Sprintf("%v", statusCode) + " " + statusMessage + "\r\n",
		ContentType: "Content-Type: text/html; charset=utf-8\r\n",
	}
	return &HTTPResponse
}

// Print http response to stdout
func (HTTPResponse *HTTPResponse) print(str ...string) {
	fmt.Print(HTTPResponse.Status + HTTPResponse.ContentType + "\r\n\r\n")
	fmt.Println(strings.Join(str, " "))
	os.Exit(0)
}

// --- //

// Exit program with a HTTP Internal Error status code and a message (dump and die)
func logError(str ...string) {
	NewHTTPResponse(500, "Internal server error").print(strings.Join(str, " "))
	os.Exit(0)
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
