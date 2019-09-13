This Dockerfile allows to build Qt applications inside a container container. It uses the awesome [qtci](https://github.com/homdx/qtci) scripts from [@homdx](https://github.com/homdx) for installing Qt, the android SDK + NDK. 
=======
[![](https://images.microbadger.com/badges/image/homdx/qt-android-docker.svg)](https://microbadger.com/images/homdx/qt-android-docker "Get your own image badge on microbadger.com")

[![](https://images.microbadger.com/badges/version/homdx/qt-android-docker.svg)](https://microbadger.com/images/homdx/qt-android-docker "Get your own version badge on microbadger.com")

[![Build Status](https://travis-ci.org/homdx/qt-android-docker.svg?branch=513)](https://travis-ci.org/homdx/qt-android-docker)

This Dockerfile allows to build Qt applications inside a container container. It uses the awesome [qtci](https://github.com/homdx/qtci) scripts from [@homdx](https://github.com/homdx) for installing Qt, the android SDK + NDK. 

Builder with Clang SDK 28 NDK r19c Qt 5.13.1

# Usage
* Download the Dockerfile to your host system with 
`wget https://raw.githubusercontent.com/homdx/qt-android-docker/master/Dockerfile`

* Change to the directory where the Dockerfile resides and build the docker container with: 

   ```docker build -t qt-android .```

  If no build arguments are specified, a docker container with Qt 5.13.1, Android NDK r19c and android-21 will be created.

  In case you want to create a docker image with different versions, change the following line accordingly: 

   ```bash
    docker build -t qt-android --build-arg QT_VERSION="5.13.1" --build-arg NDK_VERSION="r19c" --build-arg SDK_INSTALL_PARAMS="platform-tool,build-tools-28.0.2,android-21" --build-arg QT_PACKAGES="qt,qt.qt5.5131,qt.qt5.5131.gcc_64,qt.qt5.5131.android_armv7"
    ```

* Next, create a bash script on your host system, which will then be executed inside the docker container. 
  
  e.q: The script to build [Imagemonkey - TheGame](https://github.com/homdx/imagemonkey-thegame) looks like this: 

```bash
# script.sh
#!/bin/bash

export ANDROID_TARGET_SDK_VERSION=23
git clone https://github.com/homdx/imagemonkey-thegame.git /tmp/imagemonkey-thegame
build-android-gradle-project /tmp/imagemonkey-thegame/imagemonkey_thegame.pro
```

* Now, create a folder named `android-build` on your host system and run the docker container with 

`docker run --mount type=bind,source="$(pwd)/android-build",target=/android-build -i qt < script.sh` 

to build your application. Inside the `android-build` folder you should now find the apk. 
