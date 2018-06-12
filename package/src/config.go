// HTML user interface for dnscrypt-proxy
// Copyright Sebastian Schmidt
// Licence MIT
package main

var dev *bool
var rootDir string
var Files = make(map[string]string)

var ConfigFiles []Application

type Application struct {
	Name      string
	Directory string
	Files     []string
}

func NewApplication(name string, dir string, files []string) Application {
	return Application{
		Name:      name,
		Directory: dir, // prefix added to each file
		Files:     files,
	}
}

func NewConfigFiles() { // TODO load as yml/toml file
	dnscryptProxyFiles := []string{
		"dnscrypt-proxy.toml",
		"blacklist.txt",
		"cloaking-rules.txt",
		"forwarding-rules.txt",
		"whitelist.txt",
		"domains-blacklist.conf",
		"domains-whitelist.txt",
		"domains-time-restricted.txt",
		"domains-blacklist-local-additions.txt",
	}
	ConfigFiles = append(ConfigFiles, NewApplication("dnscrypt-proxy", "/dnscrypt-proxy/target/var/", dnscryptProxyFiles))

	// add yours here
}

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
