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
	"os/exec"
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

// Detect if the rune (character) contains '{' and therefore is likely to contain JSON
// returns bool
func findJSON(r rune) bool {
	return r != '{'
}

// Check if the logged in user is Authorised or Admin.
// If either fails than we return a HTTP Unauthorized error.
func auth() string {
	user, err := exec.Command("/usr/syno/synoman/webman/modules/authenticate.cgi").Output()
	if err != nil && string(user) == "" {
		if err.Error() == "exit status 7" {
			// logUnauthorised("exec()", "You are probably logged in to the DSM but I don't have a cookie :'(")
			// login to the web api:
			//https://your-ip:5001/webapi/auth.cgi?api=SYNO.API.Auth&version=3&method=login&account=admin&passwd=your_admin_password&format=cookie
			return ""
		} else if err.Error() == "exit status 5" {
			logUnauthorised("exec()", "You are unauthorised")
		} else {
			logUnauthorised("exec()", err.Error())
		}
	}
	return string(user)
}
