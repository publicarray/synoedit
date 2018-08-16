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
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"github.com/BurntSushi/toml"
	"io"
	"os"
	"path"
	"path/filepath"
)

type Config struct {
	Applications map[string]ApplicationConfig `toml:"app"`
}

type ApplicationConfig struct {
	Name      *string `toml:"name"`
	Directory *string `toml:"directory"`
	// Path                      *string       `toml:"path"`
	Files []string `toml:"files"`
	// Files  map[string] `toml:"files"`
	// Files  map[string]string `toml:"files"`
	Action ActionConfig `toml:"action"`
}

type ActionConfig struct {
	Label      *string  `toml:"button_label"`
	Exec       *string  `toml:"exec"`
	Args       []string `toml:"args"`
	Dir        *string  `toml:"dir"`
	OutputFile *string  `toml:"out-file"`
}

func newConfig() Config {
	return Config{}
}

var dev *bool

var config Config

// root directory for packages "/var/packages/"
var rootDir string

func verifyFile(filePath string, sha256checksum string) bool {
	file, err := os.Open(filePath)
	if err != nil {
		logError("Unable open file")
	}
	defer file.Close()

	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		logError("Unable read file")
	}
	checksum := hash.Sum(nil)
	// fmt.Printf("%s\n", sha256checksum)
	// fmt.Printf("%x\n", checksum)
	return hex.EncodeToString(checksum) == sha256checksum
}

// borrowed from dnscrypt-proxy
func ConfigLoad(configFile *string) error {
	foundConfigFile, err := findConfigFile(configFile)
	if err != nil {
		logError("Unable to load the configuration file")
		return err
	}
	// // This is to prevent from modifying unapproved files.
	// if !verifyFile(foundConfigFile, DefaultDatabaseSHA256Checksum) {
	// 	logError("Warning! the database.toml file has been modified! Are you sure you want to continue?")
	// }

	config = newConfig()
	md, err := toml.DecodeFile(foundConfigFile, &config)
	if err != nil {
		return err
	}
	undecoded := md.Undecoded()
	if len(undecoded) > 0 {
		return fmt.Errorf("Unsupported key in configuration file: [%s]", undecoded[0])
	}
	return nil
}

// borrowed from dnscrypt-proxy
func findConfigFile(configFile *string) (string, error) {
	if _, err := os.Stat(*configFile); os.IsNotExist(err) {
		cdLocal()
		if _, err := os.Stat(*configFile); err != nil {
			return "", err
		}
	}
	pwd, err := os.Getwd()
	if err != nil {
		return "", err
	}
	if filepath.IsAbs(*configFile) {
		return *configFile, nil
	}
	return path.Join(pwd, *configFile), nil
}

// borrowed from dnscrypt-proxy
func cdLocal() {
	exeFileName, err := os.Executable()
	if err != nil {
		logError("Unable to determine the executable directory")
		return
	}
	os.Chdir(filepath.Dir(exeFileName))
}
