#!/bin/bash

if [[ `whoami` == 'root' ]]; then
    echo "This script must not be run with sudo or as root"
    exit
fi

if [[ -e ~/langtech ]]; then
	echo "~/langtech already exists - if you really want to install from new, rename or delete the existing folder, then rerun this script."
	exit
fi

echo "Installing tools - this may ask for your sudo password"
cd /tmp/
sudo curl https://apertium.projectjj.com/osx/install-nightly.sh | sudo bash

echo "Updating MacPorts"
sudo port selfupdate
sudo port upgrade outdated

echo ""
echo "Removing unused ports"
sudo port uninstall inactive

echo ""
echo "Installing required ports"
for PKG in subversion git pkgconfig autoconf automake gawk xz perl5 p5-file-homedir p5-ipc-run p5-app-cpanminus p5-plack p5-yaml-libyaml p5-json p5-json-xs timeout python310
do
	echo "... installing $PKG"
	yes | sudo port install "$PKG" || echo "FAILED TO INSTALL $PKG"
done

sudo port select --set python3 python310

export GIELLA_CORE=~/langtech/giella-core
export GIELLA_SHARED=~/langtech/giella-shared
export PERL_UNICODE=SDA

set +e

GREP=`egrep '^export GIELLA_CORE=~/langtech/giella-core' ~/.profile ~/.zprofile 2>/dev/null`
if [[ -z "$GREP" ]]; then
	echo 'export GIELLA_CORE=~/langtech/giella-core' >> ~/.profile
	echo 'export GIELLA_CORE=~/langtech/giella-core' >> ~/.bashrc
	echo 'export GIELLA_CORE=~/langtech/giella-core' >> ~/.zprofile
fi

GREP=`egrep '^export GIELLA_SHARED=~/langtech/giella-shared' ~/.profile ~/.zprofile 2>/dev/null`
if [[ -z "$GREP" ]]; then
	echo 'export GIELLA_SHARED=~/langtech/giella-shared' >> ~/.profile
	echo 'export GIELLA_SHARED=~/langtech/giella-shared' >> ~/.bashrc
	echo 'export GIELLA_SHARED=~/langtech/giella-shared' >> ~/.zprofile
fi

GREP=`egrep '^export PERL_UNICODE=SDA' ~/.profile ~/.zprofile 2>/dev/null`
if [[ -z "$GREP" ]]; then
	echo 'export PERL_UNICODE=SDA' >> ~/.profile
	echo 'export PERL_UNICODE=SDA' >> ~/.bashrc
	echo 'export PERL_UNICODE=SDA' >> ~/.zprofile
fi

set -e

echo ""
echo "Checking out repositories"
mkdir -pv ~/langtech
pushd ~/langtech
svn co https://github.com/giellalt/giella-core/trunk giella-core
svn co https://github.com/giellalt/giella-shared/trunk giella-shared
svn co https://github.com/giellalt/shared-mul/trunk shared-mul
svn co https://github.com/giellalt/regtest-kal/trunk regression
svn co https://github.com/giellalt/lang-kal/trunk kal

pushd ~/langtech/regression
svn co https://github.com/TinoDidriksen/regtest/trunk/ regtest/
popd

echo ""
echo "Building giella-core"
pushd ~/langtech/giella-core
autoreconf -fi
./configure
make
popd

echo ""
echo "Building giella-shared"
pushd ~/langtech/giella-shared
autoreconf -fi
./configure
make
popd

echo ""
echo "Building kal"
pushd ~/langtech/kal
autoreconf -fi
./configure --without-forrest --with-hfst --without-xfst --enable-spellers --enable-hyperminimisation --enable-alignment --enable-minimised-spellers --enable-syntax --enable-analysers --enable-generators --enable-tokenisers --with-backend-format=foma --disable-hfst-desktop-spellers --disable-hfst-dekstop-spellers
make -j4
popd

mkdir -pv ~/bin
curl https://raw.githubusercontent.com/Oqaasileriffik/lt-course/master/lecture01/scripts/update-macos.sh > ~/bin/update-tools.sh
curl https://raw.githubusercontent.com/Oqaasileriffik/lt-course/master/lecture01/scripts/update-kal.sh > ~/bin/update-kal.sh
chmod +x ~/bin/*.sh
