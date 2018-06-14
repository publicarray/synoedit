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
package main
*/
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
