// HTML user interface for dnscrypt-proxy
// Copyright Sebastian Schmidt
// Licence MIT
package main

import (
	"io/ioutil"
	"os"
)

// Return true if the file path exists.
func FileExists(file string) bool {
	_, err := os.Stat(file)
	if err != nil {
		if os.IsNotExist(err) {
			return false
		}
		logError(err.Error())
	}
	return true
}

// Read file from filepath and return the data as a string
func ReadFile(file string) string {
	if FileExists(file) {
		data, err := ioutil.ReadFile(file)
		if err != nil {
			logError(err.Error())
		}
		return string(data)

	} else {
		notFound("file not found:", file)

		// // try to create the missing file
		// newFile, err := os.Create(file)
		// if err != nil {
		// 	notFound(err.Error())
		// }
		// newFile.Close()
	}
	return ""
}

// Save file content (data) to the approved file path (fileKey)
func SaveFile(file string, data string) {
	err := ioutil.WriteFile(file+".tmp", []byte(data), 0644)
	if err != nil {
		logError(err.Error())
	}

	err = os.Rename(file+".tmp", file) // atomic
	if err != nil {
		logError(err.Error())
	}
	return
}
