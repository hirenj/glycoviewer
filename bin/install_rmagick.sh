#!/bin/sh
curl -O http://download.savannah.gnu.org/releases/freetype/freetype-2.3.7.tar.gz
tar xzvf freetype-2.3.7.tar.gz
cd freetype-2.3.7
./configure --prefix=/usr/local
make
sudo make install
cd ..

curl -O http://superb-west.dl.sourceforge.net/sourceforge/libpng/libpng-1.2.29.tar.bz2
tar jxvf libpng-1.2.29.tar.bz2
cd libpng-1.2.29
./configure --prefix=/usr/local
make
sudo make install
cd ..

curl -O http://quirkysoft.googlecode.com/files/jpegsrc.v6b.tar.gz
tar xzvf jpegsrc.v6b.tar.gz
cd jpeg-6b
ln -s `which glibtool` ./libtool
export MACOSX_DEPLOYMENT_TARGET=10.5.4
./configure --enable-shared --prefix=/usr/local
make
sudo mkdir /usr/local/man/man1
sudo make install
cd ..

curl -O ftp://ftp.remotesensing.org/libtiff/tiff-3.8.2.tar.gz
tar xzvf tiff-3.8.2.tar.gz
cd tiff-3.8.2
./configure --prefix=/usr/local
make
sudo make install
cd ..

curl -O http://voxel.dl.sourceforge.net/sourceforge/wvware/libwmf-0.2.8.4.tar.gz
tar xzvf libwmf-0.2.8.4.tar.gz
cd libwmf-0.2.8.4
make clean
./configure
make
sudo make install
cd ..

curl -O http://www.littlecms.com/lcms-1.17.tar.gz
tar xzvf lcms-1.17.tar.gz
cd lcms-1.17
make clean
./configure
make
sudo make install
cd ..

curl -O ftp://mirror.cs.wisc.edu/pub/mirrors/ghost/GPL/gs860/ghostscript-8.60.tar.gz
tar zxvf ghostscript-8.60.tar.gz
cd ghostscript-8.60/
./configure  --prefix=/usr/local
make
sudo make install
cd ..

curl -O ftp.yzu.edu.tw/mirror/pub1/Unix/Tex/CTAN/support/ghostscript/GPL/gs815/ghostscript-fonts-std-8.11.tar.gz
tar zxvf ghostscript-fonts-std-8.11.tar.gz
sudo mv fonts /usr/local/share/ghostscript

curl -O ftp://ftp.imagemagick.org/pub/ImageMagick/ImageMagick-6.4.2-6.tar.gz
tar xzvf ImageMagick-6.4.2-6.tar.gz
cd ImageMagick-6.4.2
export CPPFLAGS=-I/usr/local/include
export LDFLAGS=-L/usr/local/lib
./configure --prefix=/usr/local --disable-static --with-modules --without-perl --without-magick-plus-plus --with-quantum-depth=8 --with-gs-font-dir=/usr/local/share/ghostscript/fonts
make
sudo make install
cd ..

sudo gem install rmagick