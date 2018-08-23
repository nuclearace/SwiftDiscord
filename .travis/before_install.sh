#!/bin/bash

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then
    brew tap vapor/tap
    brew update
    brew install ctls
    brew install libsodium
    brew install opus
else
    # Install Swift, Vapor and Opus
    eval "$(curl -sL https://apt.vapor.sh)"
    sudo apt-get install swift vapor libopus-dev

    # Sodium
    wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.16.tar.gz
    tar -xzf libsodium-1.0.16.tar.gz
    cd libsodium-1.0.16
    ./configure --prefix=/usr/
    make
    sudo make install
    cd ..
fi
