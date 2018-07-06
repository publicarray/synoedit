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

var dev *bool

// root directory for packages "/var/packages/"
var rootDir string

// Files contains a list of filepaths
var Files = make(map[string]string)

// ConfigFiles contains a list of Applications
var ConfigFiles []Application

// Application contains a name, config directory from rootDir onwards and config file names
type Application struct {
	Name      string
	Directory string
	Files     []string
}

// NewApplication creates a new Application object with name, config directory from rootDir onwards , and config file names
func NewApplication(name string, dir string, files []string) Application {
	return Application{
		Name:      name,
		Directory: dir, // prefix added to each file
		Files:     files,
	}
}

// NewConfigFiles contains a list of Applications with config file paths
// Insert your Application here
// TODO in the future this should be it's own file (yml or toml?)
func NewConfigFiles() {
	dnscryptProxyFiles := []string{
		"dnscrypt-proxy.toml",
		"blacklist.txt",
		"ip-blacklist.txt",
		"cloaking-rules.txt",
		"forwarding-rules.txt",
		"whitelist.txt",
		"domains-blacklist.conf",
		"domains-whitelist.txt",
		"domains-time-restricted.txt",
		"domains-blacklist-local-additions.txt",
	}
	ConfigFiles = append(ConfigFiles, NewApplication("dnscrypt-proxy", "dnscrypt-proxy/target/var/", dnscryptProxyFiles))

	// add yours here
}

// GetFilePath returns the complete file path given the App and file name
func GetFilePath(appName string, fileName string) string {
	for _, app := range ConfigFiles {
		if app.Name == appName {
			// verify the fileName is allowed
			for _, file := range app.Files {
				if file == fileName {
					return rootDir + app.Directory + fileName
				}
			}
			logError("File not found in App configuration!")
			return "" // exit early (file not found)
		}
	}
	logError("App not found in configuration!")
	return "" // exit early (app not found)
}
