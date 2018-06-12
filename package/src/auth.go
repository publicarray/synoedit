// HTML user interface for dnscrypt-proxy
// Copyright Sebastian Schmidt
// Licence MIT
package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"os"
	"os/exec"
	"regexp"
)

// AppPrivilege is part of AuthJSON
type AppPrivilege struct {
	IsPermitted bool `json:"SYNO.SDS.DNSCryptProxy.Application"`
}

// Session is part of AuthJSON
type Session struct {
	IsAdmin bool `json:"is_admin"`
}

// AuthJSON is used to read JSON data from /usr/syno/synoman/webman/initdata.cgi
type AuthJSON struct {
	Session      Session `json:"session"`
	AppPrivilege AppPrivilege
}

// Retrieve login status and try to retrieve a CSRF token.
// If either fails than we return an error to the user that they need to login.
// Returns username or error
func token() (string, error) {
	cmd := exec.Command("/usr/syno/synoman/webman/login.cgi")
	cmdOut, err := cmd.Output()
	if err != nil && err.Error() != "exit status 255" { // in the Synology world, error code 255 apparently means success!
		return string(cmdOut), err
	}
	// cmdOut = bytes.TrimLeftFunc(cmdOut, findJSON)

	// Content-Type: text/html [..] { "SynoToken" : "GqHdJil0ZmlhE", "result" : "success", "success" : true }
	r, err := regexp.Compile("SynoToken\" *: *\"([^\"]+)\"")
	if err != nil {
		return string(cmdOut), err
	}
	token := r.FindSubmatch(cmdOut)
	if len(token) < 1 {
		return string(cmdOut), errors.New("Sorry, you need to login first!")
	}
	return string(token[1]), nil
}

// Detect if the rune (character) contains '{' and therefore is likely to contain JSON
// returns bool
func findJSON(r rune) bool {
	if r == '{' {
		return false
	}
	return true
}

// Check if the logged in user is Authorised or Admin.
// If either fails than we return a HTTP Unauthorized error.
func auth() {
	token, err := token()
	if err != nil {
		logUnauthorised(err.Error())
	}

	// X-SYNO-TOKEN:9WuK4Cf50Vw7Q
	// http://192.168.1.1:5000/webman/3rdparty/DownloadStation/webUI/downloadman.cgi?SynoToken=9WuK4Cf50Vw7Q
	tempQueryEnv := os.Getenv("QUERY_STRING")
	os.Setenv("QUERY_STRING", "SynoToken="+token)
	cmd := exec.Command("/usr/syno/synoman/webman/modules/authenticate.cgi")
	user, err := cmd.Output()
	if err != nil && string(user) == "" {
		logUnauthorised(err.Error())
	}

	// check permissions
	cmd = exec.Command("/usr/syno/synoman/webman/initdata.cgi") // performance hit
	cmdOut, err := cmd.Output()
	if err != nil {
		logUnauthorised(err.Error())
	}
	cmdOut = bytes.TrimLeftFunc(cmdOut, findJSON)

	var jsonData AuthJSON
	if err := json.Unmarshal(cmdOut, &jsonData); err != nil { // performance hit
		logUnauthorised(err.Error())
	}

	isAdmin := jsonData.Session.IsAdmin              // Session.IsAdmin:true
	isPermitted := jsonData.AppPrivilege.IsPermitted // AppPrivilege.SYNO.SDS.DNSCryptProxy.Application:true
	if !(isAdmin || isPermitted) {
		notFound()
	}

	os.Setenv("QUERY_STRING", tempQueryEnv)
	return
}
