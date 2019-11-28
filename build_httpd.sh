#!/bin/bash
set -e 

# Apache and APR Versions
httpdVer="2.4.41"
aprVer="1.7.0"
aprutilVer="1.6.1"

echo "##### Building apache-httpd-$httpdVer #####
httpd version   : $httpdVer
apr version     : $aprVer
aprutil version : $aprutilVer "

# Download link for httpd, APR, APR-UTI.
 httpdURL="https://archive.apache.org/dist/httpd/httpd-$httpdVer.tar.gz"  
   aprURL="https://archive.apache.org/dist/apr/apr-$aprVer.tar.gz"
  utilURL="https://archive.apache.org/dist/apr/apr-util-$aprutilVer.tar.gz"

PKGS=$(dirname $(readlink -f "$0") )      # Get Script Directory
DEVENV=/opt/DevEnv ; mkdir -p $DEVENV     # Installation DEVENV

# Download & Move Function ---------------------------------------------------# 
function dlnmv() {
  URL=$1; Dest=$2
  wget -P $PKGS -c $URL
  pkg_name=$(echo $URL | awk -F/ '{print $NF}')
  tar -xzf $PKGS/$pkg_name -C $DEVENV
  pkg_folder=$(tar -tf $PKGS/$pkg_name | awk -F/ 'NR==1{print $1}')
  mv  $DEVENV/$pkg_folder $Dest
}

# Building Apache 2.4 --------------------------------------------------------#
echo "Installing dependencies ..."
yum -y install wget make gcc openssl-devel pcre-devel perl tar expat-devel
echo "Downloading Packages ..."
dlnmv $httpdURL $DEVENV/httpd                     # Downloading httpd
dlnmv $aprURL   $DEVENV/httpd/srclib/apr          # Downloading APR
dlnmv $utilURL  $DEVENV/httpd/srclib/apr-util     # Downloading APR UTIL
echo -e "\nBuilding Apache ...\n"
cd $DEVENV/httpd
./configure -q 	--prefix=/opt/apache \
		--enable-mods-shared="all" \
		--with-included-apr	&& make -s && make -s install

rm -rf $DEVENV/httpd

/opt/apache/bin/apachectl -V

# Server Status
cat <<EOF >> /opt/apache/conf/httpd.conf
# Server Status
<Location "/server-status">
    SetHandler server-status
    Require host localhost
</Location>
EOF

# Virtual hosts
sed -i '/httpd-vhosts\.conf/s/^.*$/Include\ conf\/vhost\.d\/\*\.conf/' /opt/apache/conf/httpd.conf
mkdir /opt/apache/conf/vhost.d
cat <<EOF > /opt/apache/conf/vhost.d/000-default.conf
<VirtualHost *:80>
</VirtualHost>
EOF

cd /opt
tar -czf /build/apache-httpd-$httpdVer.tgz apache --remove-files