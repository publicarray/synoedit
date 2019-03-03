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

// Package synoedit is a Synology package for editing files through a web interface
package main

import (
	"flag"
	"fmt"
	"html/template"
	"net/http/cgi"
	"os"
	"strings"
)

const (
	// AppVersion is the Program Version
	AppVersion = "0.0.4"
	// DefaultDatabaseFileName is the main file name for database
	DefaultDatabaseFileName = "database.toml"
	// DefaultDatabaseSHA256Checksum is used to detect manipulation or corruption
	DefaultDatabaseSHA256Checksum = "920e32a1f8e82ba20faa07b48770473052590c3a81578ef8e318f35ff14ffdc9"
	// DefaultConfigFileName = "synoedit.toml"
)

// Page contains the data that is passed to the template (layout.html)
type Page struct {
	Title          string
	FileData       string
	ErrorMessage   string
	SuccessMessage string
	File           string
	CurrentApp     string
	DevEnvironment bool
	Applications   map[string]ApplicationConfig
}

// Return HTML from layout.html.
func renderHTML(fileData string, successMessage string, errorMessage string) {
	var page Page

	tmpl, err := template.ParseFiles("layout.html")
	if err != nil {
		logError(err.Error())
	}

	page.Title = "Syno Edit"
	page.File = ""
	page.CurrentApp = "dnscrypt-proxy"
	page.FileData = fileData
	page.Applications = config.Applications
	page.ErrorMessage = errorMessage
	page.SuccessMessage = successMessage
	page.DevEnvironment = *dev
	fmt.Print(
		"Status: 200 OK\r\n",
		"Content-Type: text/html; charset=utf-8\r\n",
		"Server: synoedit ", AppVersion, "\r\n",
		"\r\n")
	err = tmpl.Execute(os.Stdout, page)
	if err != nil {
		logError(err.Error())
	}
	os.Exit(0)
}

func main() {
	// Todo:
	// fix-up error handling with correct http responses (add --debug flag?/Synology's notifications?)
	// worry about csrf

	dev = flag.Bool("dev", false, "Turns Authentication checks off")
	configFile := flag.String("config", DefaultDatabaseFileName, "Path to the configuration file")
	flag.Parse()

	if err := ConfigLoad(configFile); err != nil {
		fmt.Println(err)
		os.Exit(1)
		// dlog.Fatal(err)
	}

	if *dev { // test environment
		pwd, err := os.Getwd()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		rootDir = pwd + "/test/"
	} else { // production environment
		auth()
		rootDir = "/var/packages/"
	}

	// Retrieve Form Values
	httpReqest, err := cgi.Request()
	if err != nil {
		logError(err.Error())
	}
	if err = httpReqest.ParseForm(); err != nil {
		logError(err.Error())
	}

	ajax := strings.TrimSpace(httpReqest.FormValue("ajax"))
	appName := strings.TrimSpace(httpReqest.FormValue("app"))
	fileName := strings.TrimSpace(httpReqest.FormValue("file"))
	action := strings.TrimSpace(httpReqest.FormValue("action"))
	fileData := strings.TrimSpace(httpReqest.FormValue("fileContent"))

	// Http
	method := os.Getenv("REQUEST_METHOD")
	if method == "POST" || method == "PUT" || method == "PATCH" { // POST
		if action != "" && appName != "" {
			output := ExecuteAction(appName)

			if ajax == "true" {
				jsonMessage(0, output)
			}
			renderHTML(fileData, "Not implemented", "")
		}

		if fileData != "" && appName != "" && fileName != "" {
			filePath := GetFilePath(appName, fileName)
			SaveFile(filePath, fileData)

			if ajax == "true" {
				jsonMessage(0, "File saved successfully!")
			}
			renderHTML(fileData, "File saved successfully!", "") // not complete
		}
		logError("No valid data submitted.")
	}

	if method == "GET" { // GET
		if appName != "" && fileName != "" {
			fileData = ReadFile(GetFilePath(appName, fileName))
		}

		if ajax == "true" {
			// expect an ajax response
			jsonMessage(0, fileData)
		}
		// else respond with full html
		renderHTML(fileData, "", "") // not complete
	}

	renderHTML("", "", "")
}
