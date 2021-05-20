#!/bin/bash
echo Check Multicast server present
if [ -f "v4UdpMcastSrv" ]; then
    echo Multicast Server Found;
else
    wget -4 https://raw.githubusercontent.com/swaaws/help/main/v4UdpMcastSrv.go
    if [ `go version | grep -c "."` ]; then
        echo go found
        go build v4UdpMcastSrv.go
    else
        echo Please install golang
        exit
    fi
fi
echo Run Mcast Server for Massive Deployment: ./v4UdpMcastSrv
