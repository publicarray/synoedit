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
	"io/ioutil"
	"os"
)

// FileExists returns true if the file path exists.
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

// ReadFile reads the contents as a string, given the filepath
func ReadFile(file string) string {
	if FileExists(file) {
		data, err := ioutil.ReadFile(file)
		if err != nil {
			logError(err.Error())
		}
		return string(data)

	}
	logError("File not found:", file)
	return ""
}

// Make folder if it doesn't exist
func mkdir(path string) {
	stat, err := os.Stat(path)
	if err != nil {
		if os.IsNotExist(err) {
			if err := os.Mkdir(path, 0755); err != nil {
				logError(err.Error())
			}
			return
		}
		logError(err.Error())
	}

	if !stat.IsDir() {
		logError("Can't create folder: " + path + "exists and is not a folder")
	}

}

// SaveFile saves the file content (data) to file
func SaveFile(file string, data string) {
	// If file exists get file info struct
	fInfo, err := os.Stat(file)
	if err != nil {
		logError(err.Error())
	}

	ver := GetOSVersion()
	path := "/var/packages/synoedit/target/tmp"
	if ver.Major >= 7 {
		path = "/var/packages/synoedit/tmp"
	}

	// Create file
	mkdir(path) // (DSM6)
	tmpFile, err := ioutil.TempFile(path, "*.txt")
	if err != nil {
		logError("Cannot create temporary file", err.Error())
	}
	defer os.Remove(tmpFile.Name())
	defer tmpFile.Close()

	// Write Data
	if _, err = tmpFile.WriteString(data); err != nil {
		logError(err.Error())
	}

	if err := tmpFile.Sync(); err != nil {
		logError("can't flush file", err.Error())
	}

	// set owner and group id
	// Get stat structure (for uid and gid)
	// stat := fInfo.Sys().(*syscall.Stat_t)
	// if err := tmpFile.Chown(int(stat.Uid), int(stat.Gid)); err != nil {
	// 	logError(err.Error())
	// }

	// Close the file
	if err := tmpFile.Close(); err != nil {
		logError(err.Error())
	}

	// set owner and group id
	// if err := os.Chown(tmpFile.Name(), int(stat.Uid), int(stat.Gid)); err != nil {
	// 	logError(err.Error())
	// }

	// Set original permissions
	// if err := os.Chmod(tmpFile.Name(), 0664); err != nil {
	if err := os.Chmod(tmpFile.Name(), fInfo.Mode()); err != nil {
		logError(err.Error())
	}

	// atomic move
	if err = os.Rename(tmpFile.Name(), file); err != nil {
		logError(err.Error())
	}
}
