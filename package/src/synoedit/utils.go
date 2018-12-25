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
	"bytes"
	"os/exec"
)

// GetFilePath returns the complete file path given the App and file name
func GetFilePath(appName string, fileName string) string {
	if app, exists := config.Applications[appName]; exists {
		for _, file := range app.Files {
			if file == fileName {
				return rootDir + app.Directory + fileName
			}
		}
		logError("File not found in App configuration!")
		return ""
	}
	logError("App not found in configuration!")
	return ""
}

// CheckCmdExists returns true when the command (cmd)
// is found in the $PATH variable or when the file exits
func CheckCmdExists(cmd string) bool {
	_, err := exec.LookPath(cmd)
	if err != nil {
		return FileExists(cmd)
	}
	return true
}

// ExecuteAction runs a custom action given the application name
func ExecuteAction(appName string) string {
	if app, exists := config.Applications[appName]; exists {

		if !CheckCmdExists(app.Action.Exec) {
			logError("Command could not be found or is not installed!")
		}

		var stderr bytes.Buffer
		cmd := exec.Command(app.Action.Exec, app.Action.Args...)
		cmd.Dir = app.Action.Dir
		cmd.Stderr = &stderr
		stdout, err := cmd.Output()
		if err != nil {
			logError(string(stdout) + err.Error())
		}
		if len(app.Action.OutputFile) > 0 {
			filePath := GetFilePath(appName, app.Action.OutputFile)
			SaveFile(filePath, string(stdout))
		}
		return string(stdout) + string(stderr.Bytes())
	}
	logError("App not found in configuration!")
	return ""
}
