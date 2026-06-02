# On classic — source SDK and build:
. /opt/poky/5.0.17/environment-setup-cortexa9t2hf-neon-poky-linux-gnueabi

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=$(pwd)/usr
make && make install

# Deploy to board:
scp usr/bin/hps_music_player root@192.168.100.50:/usr/bin/

# On board (with FPGA programmed):
fpga_mem_test
