// HTML user interface for dnscrypt-proxy
// Copyright Sebastian Schmidt
// Licence MIT
package main

import (
	"os/exec"
)

// Look for command in $PATH
func CheckCmdExists(cmd string) bool {
	_, err := exec.LookPath(cmd)
	if err != nil {
		return false
	}
	return true
}
