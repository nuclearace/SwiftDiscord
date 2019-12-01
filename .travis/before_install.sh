#!/bin/bash

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then
    brew tap vapor/tap
    brew update
    brew install ctls
    brew install libsodium
    brew install opus
else
    git clone https://github.com/kylef/swiftenv.git ~/.swiftenv
    echo 'export SWIFTENV_ROOT="$HOME/.swiftenv"' >> ~/.bash_profile
    echo 'export PATH="$SWIFTENV_ROOT/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(swiftenv init -)"' >> ~/.bash_profile

    reload
    swiftenv install 5.1 && swiftenv global 5.1

    # Install  Vapor and Opus
    eval "$(curl -sL https://apt.vapor.sh)"
    sudo apt-get install vapor libopus-dev

    # Sodium
    wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.16.tar.gz
    tar -xzf libsodium-1.0.16.tar.gz
    cd libsodium-1.0.16
    ./configure --prefix=/usr/
    make
    sudo make install
    cd ..
fi
