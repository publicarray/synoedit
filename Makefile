## You can use CC CFALGS LD LDFLAGS CXX CXXFLAGS AR RANLIB READELF STRIP after include env.mak
include /env.mak

BIN=package/ui/index.cgi
OBJS=package/src/*.go

ARM5_ARCHES=88f6281
ARM7_ARCHES=alpine armada370 armada375 armada38x armadaxp comcerto2k monaco hi3535 ipq806x northstarplus
ARM8_ARCHES=rtd1296
ARM_ARCHES=$(ARM5_ARCHES) $(ARM7_ARCHES) $(ARM8_ARCHES)
PPC_ARCHES=powerpc ppc824x ppc853x ppc854x qoriq
x86_ARCHES=evansport
x64_ARCHES=apollolake avoton braswell broadwell broadwellnk bromolow cedarview denverton dockerx64 grantley kvmx64 x86 x64 x86_64

# ARCH
# SYNO_PLATFORM
# DSM_SHLIB_MAJOR
# DSM_SHLIB_MINOR
# DSM_SHLIB_NUM

GOARM=""
ifeq ($(findstring $(ARCH),$(ARM5_ARCHES)),$(ARCH))
GOARCH = arm
GOARM=5
endif
ifeq ($(findstring $(ARCH),$(ARM7_ARCHES)),$(ARCH))
GOARCH = arm
GOARM=7
endif
ifeq ($(findstring $(ARCH),$(ARM8_ARCHES)),$(ARCH))
GOARCH = arm64
endif
ifeq ($(findstring $(ARCH),$(x86_ARCHES)),$(ARCH))
GOARCH = 386
endif
ifeq ($(findstring $(ARCH),$(x64_ARCHES)),$(ARCH))
GOARCH = amd64
endif
ifeq ($(findstring $(ARCH),$(PPC_ARCHES)),$(ARCH))
GOARCH = ppc64
endif
ifeq ($(GOARCH),)
$(error Unsupported ARCH $(ARCH))
endif

all: $(BIN)

# $(BIN): $(OBJS)
# 	 $(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

$(BIN):
	echo "make BIN"
	# wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz -o /tmp/go1.10.3.linux-amd64.tar.gz
	# tar -C /usr/local -xzvf /tmp/go1.10.3.linux-amd64.tar.gz
	echo "GOARCH=$(GOARCH) GOARM=$(GOARM)"
	# echo "go version"
	# go version
	echo "/usr/local/go/bin/go version"
	/usr/local/go/bin/go version
	echo "go build"
	env GOOS=linux GOARCH="$(GOARCH)" GOARM="$(GOARM)" /usr/local/go/bin/go build -ldflags "-s -w" -o $(BIN) -- package/src/*.go

install:
	echo "make install"
	mkdir -p $(DESTDIR)
	cp -rfv package/ui $(DESTDIR)
	# install $< $(DESTDIR)

clean:
	rm -rf $(BIN)
