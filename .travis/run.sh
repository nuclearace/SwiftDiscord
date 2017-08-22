#!/bin/bash

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then
    swift test -Xlinker -L/usr/local/lib -Xlinker -lopus -Xcc -I/usr/local/include
else
    swift test -Xlinker -L/usr/lib -Xlinker -lopus -Xcc -I/usr/include
fi
