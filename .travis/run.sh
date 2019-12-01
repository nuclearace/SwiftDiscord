#!/bin/bash

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then
    swift test
else
    git clone https://github.com/kylef/swiftenv.git ~/.swiftenv
    echo 'export SWIFTENV_ROOT="$HOME/.swiftenv"' >> ~/.bash_profile
    echo 'export PATH="$SWIFTENV_ROOT/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(swiftenv init -)"' >> ~/.bash_profile
    source ~/.bash_profile

    # Swift
    swiftenv install 5.1 && swiftenv global 5.1
    swift --version
    swift test
fi
