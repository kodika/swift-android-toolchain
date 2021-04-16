#!/bin/bash

# Starting from Ubuntu 20.04 Python 3 is default Python
# https://wiki.ubuntu.com/FocalFossa/ReleaseNotes#Python3_by_default
# But all swift build script rely on /usr/bin/python which should be Python2

# Prinnt current version of /usr/bin/python
/usr/bin/python --version

# Install Python 2
apt install python2

# Print version of Python2 and Python3
python2 --version
python3 --version

update-alternatives --install /usr/bin/python python /usr/bin/python2 1

# Prinnt current version of /usr/bin/python
/usr/bin/python --version