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
	"flag"
	"fmt"
	"html/template"
	"io/ioutil"
	"net/url"
	"os"
)

const (
	AppVersion = "0.0.0"
	// DefaultConfigFileName = "synoedit.toml"
	DefaultDatabaseFileName       = "database.toml"
	DefaultDatabaseSHA256Checksum = "69cb67d90d25127296a0217a19a321fe1a807982e3330ff28f8fe861ad19ef73"
)

// Page contains the data that is passed to the template (layout.html)
type Page struct {
	Title          string
	FileData       string
	ErrorMessage   string
	SuccessMessage string
	File           string
	CurrentApp     string
	Applications   map[string]ApplicationConfig
}

// https://stackoverflow.com/questions/44675087/golang-template-variable-isset
// func templateIsset(name string, data interface{}) bool {
// 	v := reflect.ValueOf(data)
// 	if v.Kind() == reflect.Ptr {
// 		v = v.Elem()
// 	}
// 	if v.Kind() != reflect.Struct {
// 		return false
// 	}
// 	return v.FieldByName(name).IsValid()
// }

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
	fmt.Print("Status: 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nServer: synoedit", AppVersion)
	fmt.Print("\r\n\r\n")
	err = tmpl.Execute(os.Stdout, page)
	if err != nil {
		logError(err.Error())
	}
	os.Exit(0)
}

// Read GET parameters and return them as an Object
func readGet() url.Values {
	queryStr := os.Getenv("QUERY_STRING")
	q, err := url.ParseQuery(queryStr)
	if err != nil {
		logError(err.Error())
	}
	return q
}

// Read POST parameters and return them as an Object
func readPost() url.Values { // todo: stop on a max size (10mb?)
	// fixme: check/generate csrf token
	bytes, err := ioutil.ReadAll(os.Stdin) // if there is no data the process will block (wait)
	if err != nil {
		logError(err.Error())
	}

	q, err := url.ParseQuery(string(bytes))
	if err != nil {
		logError(err.Error())
	}
	return q
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

	// Http
	method := os.Getenv("REQUEST_METHOD")
	if method == "POST" || method == "PUT" || method == "PATCH" { // POST
		postData := readPost()
		fileData := postData.Get("fileContent")
		ajax := postData.Get("ajax")
		appName := postData.Get("app")
		fileName := postData.Get("file")
		action := postData.Get("action")
		if action != "" && appName != "" {
			output := ExecuteAction(appName)

			if ajax == "true" {
				fmt.Print("Status: 200 OK\r\nContent-Type: text/plain;\r\n\r\n")
				fmt.Print(output)
				return
			}
			renderHTML(fileData, "Not implemented", "")
			return
		}

		if fileData != "" && appName != "" && fileName != "" {
			filePath := GetFilePath(appName, fileName)
			SaveFile(filePath, fileData)

			if ajax == "true" {
				fmt.Print("Status: 200 OK\r\nContent-Type: text/plain;\r\n\r\n")
				fmt.Print("File saved successfully!")
				return
			}
			renderHTML(fileData, "File saved successfully!", "") // not complete
			return
		}
		logError("No valid data submitted.")
		return
	}

	if method == "GET" { // GET
		var fileData = ""
		appName := readGet().Get("app")
		fileName := readGet().Get("file")
		if appName != "" && fileName != "" {
			fileData = ReadFile(GetFilePath(appName, fileName))
		}

		if ajax := readGet().Get("ajax"); ajax == "true" {
			// expect an ajax response
			fmt.Print("Status: 200 OK\r\nContent-Type: text/plain;\r\n\r\n")
			fmt.Print(fileData)
			return
		}
		// else respond with full html
		renderHTML(fileData, "", "") // not complete
	}

	renderHTML("", "", "")
}
