apt-get install -y  python-software-properties
add-apt-repository -y ppa:juju/pkgs

apt-get update 

#&& apt-get upgrade # haha

apt-get install -y juju apt-cacher-ng libvirt-bin lxc zookeeper # juju 

export AS_USER="sudo su vagrant -c"

$AS_USER "mkdir -p /home/vagrant/.juju"

$AS_USER "echo $'
environments:
  local:
    type: local
    data-dir: /home/vagrant/tsuru
    admin-secret: b3a5dee4fb8c4fc9a4db04751e5936f4
    default-series: precise
' > /home/vagrant/.juju/environments.yaml"

$AS_USER "mkdir -p /home/vagrant/tsuru"
chmod 777 /home/vagrant/tsuru # FIX IT

if [ ! -d "/home/vagrant/.ssh/id_rsa" ]; then
  $AS_USER "ssh-keygen -t dsa -N '' -C 'juju key' -f id_rsa"
fi

$AS_USER "juju bootstrap"
