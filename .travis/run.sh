#!/bin/bash

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then
    swift test
else
    swiftenv global 5.1
    swift --version
    swift test
fi
