#!/bin/sh
. /pkgscripts-ng/include/pkg_util.sh

package="synoedit"
displayname="Syno Edit"
version="1.0.0"
firmware="1.1.0-0"
description="A simple text editor GUI for Synology. JavaScript editor implemented using CodeMirror."
arch="$(pkg_get_platform) "
maintainer="publicarray"
maintainer_url="https://github.com/publicarray/synoedit"
distributor="publicarray"
distributor_url="https://github.com/publicarray/synoedit"
support_url="https://github.com/publicarray/synoedit/issues"
helpurl="https://github.com/publicarray/synoedit/wiki"
dsmuidir="ui"
dsmappname="com.publicarray.synoedit"
helpurl="https://github.com/publicarray/synoedit"
thirdparty="yes"
startable="no"
ctl_stop="no"
[ "$(caller)" != "0 NULL" ] && return 0
pkg_dump_info
