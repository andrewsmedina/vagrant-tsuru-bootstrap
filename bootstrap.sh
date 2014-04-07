apt-get update # this is important

apt-get install -y  python-software-properties
add-apt-repository -y ppa:juju/pkgs # juju repo

# 10 gen MongoDB
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10 # 10 gen public key
echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" > /etc/apt/sources.list.d/10gen.list

apt-get update 

#&& apt-get upgrade # haha

apt-get install -y juju apt-cacher-ng libvirt-bin lxc zookeeper # juju 
apt-get install -y mongodb-10gen # mongodb
apt-get install -y git beanstalkd curl # tsuru

export AS_USER="sudo su vagrant -c"

$AS_USER "git clone git://github.com/globocom/charms.git /home/vagrant/charms" # tsuru charms

$AS_USER "mkdir -p /home/vagrant/.juju"

$AS_USER "echo $'
environments:
  local:
    type: local
    data-dir: /home/vagrant/tsuru
    admin-secret: b3a5dee4fb8c4fc9a4db04751e5936f4
    default-series: precise
    charms: /home/vagrant/charms
' > /home/vagrant/.juju/environments.yaml"

$AS_USER "mkdir -p /home/vagrant/tsuru"
chmod 777 /home/vagrant/tsuru # FIX IT

if [ ! -d "/home/vagrant/.ssh/id_rsa" ]; then
  $AS_USER "ssh-keygen -t dsa -N '' -C 'juju key' -f id_rsa"
fi

echo '### Services ###'

echo '> Run mongodb'
service mongodb start

echo '> Run beanstalkd'
service beanstalkd start

echo '### juju ##'

$AS_USER "juju bootstrap"

echo "### TSURU ###"
apt-get install -y golang-go git mercurial bzr gcc
echo 'export GOPATH=/home/vagrant/.go' >> /home/vagrant/.bashrc
echo 'export PATH=${GOPATH}/bin:${PATH}' >> /home/vagrant/.bashrc
$AS_USER 'source ~/.bashrc'
$AS_USER 'go get github.com/tsuru/tsuru/api'
$AS_USER 'go get github.com/tsuru/tsuru/collector'


#echo '> Download tsuru collector'
#curl -sL https://s3.amazonaws.com/tsuru/dist-server/tsuru-collector.tar.gz | sudo tar -xz -C /usr/bin
#
#echo '> Download tsuru api'
#curl -sL https://s3.amazonaws.com/tsuru/dist-server/tsuru-api.tar.gz | sudo tar -xz -C /usr/bin

echo '> Configure tsuru'
mkdir -p /etc/tsuru
# curl -sL https://raw.github.com/tsuru/tsuru/master/etc/tsuru.conf -o /etc/tsuru/tsuru.conf

echo $'
listen: "0.0.0.0:8080"
use-tls: false
database:
  url: 127.0.0.1:27017
  name: tsuru
git:
  unit-repo: /home/application/current
  host: 127.0.0.1
  protocol: http
  port: 8000
bucket-support: false
auth:
  salt: tsuru-salt
  token-expire-days: 2
  token-key: TSURU-KEY
  hash-cost: 4
juju:
  charms-path: /home/vagrant/charms
  units-collection: juju_units
queue-server: "127.0.2.1:11300"
provisioner: docker
docker:
  collection: docker
  authorized-key-path: /home/vagrant/.ssh/id_rsa.pub
  formulas-path: /home/vagrant/charms/precise
  domain: godock.org
  routes-path: /etc/nginx/sites-enabled
  ip-timeout: 200
  binary: /home/vagrant/.go/bin/docker
admin-team: admin' > /etc/tsuru/tsuru.conf

# gandalf

echo '> Download Gandalf'
curl -sL https://s3.amazonaws.com/tsuru/dist-server/gandalf-bin.tar.gz | sudo tar -xz -C /usr/bin

echo '> Download Gandalf webserver'
curl -sL https://s3.amazonaws.com/tsuru/dist-server/gandalf-webserver.tar.gz | sudo tar -xz -C /usr/bin

echo '> Configure Gandalf'
echo 'bin-path: /usr/bin/gandalf-bin
database:
    url: 127.0.0.1:27017
    name: gandalf
git:
    bare:
        location: /var/repositories
        #template: /home/git/bare-template # optional
host: localhost
webserver:
    port: ":8000"
uid: git' > /etc/gandalf.conf

echo '> Run Gandalf'
#gandalf-webserver &

echo '> Run git daemon'
useradd git
mkdir -p /home/git/.ssh
touch /home/git/.ssh/authorized_keys
mkdir -p /var/repositories
chown git:git -R /var/repositories
chown git:git -R /home/git
#git daemon --base-path=/var/repositories --syslog --export-all &

echo "install docker"
apt-get -y install lxc wget bsdtar curl vim
echo 'download docker'
wget http://get.docker.io/builds/$(uname -s)/$(uname -m)/docker-master.tgz 
tar -xf docker-master.tgz
echo '### The END ###'
