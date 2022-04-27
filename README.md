## docker-adb
Run ADB server on Docker containers with access to host's USB devices. This dockerfile uses [android-tools][1] to build ADB server without all the bloat of AOSP. 

Tested on **Ubuntu** 20+ hosts only.

## Usage
On host system it's needed to give USB devices access to plugdev group, for that create a new udev rule at `/etc/udev/rules.d/51-android.rules`:
```
# LG
SUBSYSTEM=="usb", ATTR{idVendor}=="1004", MODE="0660", GROUP="plugdev"
# SAMSUNG
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0660", GROUP="plugdev"
# ...
```
where you need a new rule for each smartphone vendor you have. Then reload udev rules with `sudo udevadm control --reload-rules && sudo udevadm trigger`.

Create a new group `adb` with `sudo groupadd -r adb` and append the following env vars to `~/.bashrc` (or `~/.zshrc`):
```bash
export PLUGDEV_GID=$(getent group plugdev | cut -d: -f3)
export ADB_GID=$(getent group adb | cut -d: -f3)
```
then reload bashrc with `source ~/.bashrc`.

Build the Docker image with:
```bash
git clone
cd docker-adb
docker build -t adbserver .
```
You can target different releases of android-tools with `--build-arg RELEASE=X` where `X` is the release version number found at their [releases page][2]. 

After the image is successfully built, you can create a new adb container with:
```bash
mkdir adbkeys
ln -sr <ADB_PRIVATE_KEY_FILE> adbkeys/adbkey
ln -sr <ADB_PUBLIC_KEY_FILE> adbkeys/adbkey.pub
chown :adb <ADB_PRIVATE_KEY_FILE> <ADB_PUBLIC_KEY_FILE>
chmod g=r <ADB_PRIVATE_KEY_FILE> <ADB_PUBLIC_KEY_FILE>
docker run -d \
    -v ./adbkeys/adbkey:/home/adb/.android/adbkey \
    -v ./adbkeys/adbkey.pub:/home/adb/.android/adbkey.pub \
    -v /dev/bus/usb:/dev/bus/usb \
    -v /run/udev:/run/udev:ro \
    --device-cgroup-rule "c 188:* rmw" \
    --device-cgroup-rule "c 189:* rmw" \
    --group-add $PLUGDEV_GID \
    --group-add $ADB_GID \
    --name adb \
    adbserver
```
where `<ADB_PRIVATE_KEY_FILE>` is the path to ADB public key file and `<ADB_PRIVATE_KEY_FILE>` to the private key file, they are commonly found at `~/.android/adbkey` and `~/.android/adbkey.pub` respectively. If you don't have already generated keys you can skip these steps and let ADB generate new keys within the container, but these keys will be regenerated every time the container is recreated and you will need to authorize new debugging clients on your smartphone.

You also can start adb container with compose: `docker-compose up -d adb`.

That's it, you have a non-root ADB server container! You can get a shell with `docker exec adb bash` and use ADB client to inspect devices (e.g. `adb devices`). You also can use `lsusb` to check if underlying USB device for your smartphone is available.

## Debugging
To troubleshoot issues you may use a debug build of ADB server, the `Dockerfile.debug` dockerfile builds a debug environment with debug build of ADB and the GDB debugger ready to be used.

<br>
<hr>
docker-adb is licensed under the MIT License.
<hr>

[1]: https://github.com/nmeum/android-tools
[2]: https://github.com/nmeum/android-tools/releases