## Build with Yocto SDK

```bash
. /opt/poky/5.0.15/environment-setup-cortexa7t2hf-neon-vfpv4-poky-linux-gnueabi
cd robot-6.0.1 && rm -rf build && mkdir build && cd build
cmake ../ -DCMAKE_INSTALL_PREFIX:PATH=$(pwd)/usr
make && make install
```

---

## Deploy to the Pi

For live iteration without reflashing the image (you may need to alter the ip address):

```bash
# Kill the auto-started daemon first
ssh root@192.168.100.131 'kill $(pidof robot_main) 2>/dev/null; sleep 1'

# Shared libraries
scp usr/lib/lib*.so* root@192.168.100.131:/usr/lib/
# Binaries
scp usr/bin/robot_test usr/bin/robot_main root@192.168.100.131:/usr/bin/
# Config
scp ../robot.cfg root@192.168.100.131:/etc/robot.cfg
# Static web assets
ssh root@192.168.100.131 'mkdir -p /usr/share/robot/www'
scp -r ../www/* root@192.168.100.131:/usr/share/robot/www/

# Restart
ssh root@192.168.100.131 '/etc/init.d/robot start'
```