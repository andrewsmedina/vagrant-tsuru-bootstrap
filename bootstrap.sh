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

$AS_USER "juju bootstrap"


echo "### TSURU ###"

curl -sL https://s3.amazonaws.com/tsuru/dist-server/tsuru-collector.tar.gz | sudo tar -xz -C /usr/bin

curl -sL https://s3.amazonaws.com/tsuru/dist-server/tsuru-api.tar.gz | sudo tar -xz -C /usr/bin

mkdir /etc/tsuru
curl -sL https://raw.github.com/globocom/tsuru/master/etc/tsuru.conf -o /etc/tsuru/tsuru.conf

# tsuru gandalf

curl -sL https://s3.amazonaws.com/tsuru/dist-server/gandalf-bin.tar.gz | sudo tar -xz -C /usr/bin
curl -sL https://s3.amazonaws.com/tsuru/dist-server/gandalf-webserver.tar.gz | sudo tar -xz -C /usr/bin

curl -sL https://raw.github.com/globocom/gandalf/master/etc/gandalf.conf -o /etc/gandalf.conf

webserver &

git daemon --base-path=/var/repositories --syslog --export-all &
