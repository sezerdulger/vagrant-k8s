#!/bin/bash -x


echo "provisioning $hostname with $ip"
hostnamectl set-hostname k8s-master-lb
cp /vagrant/hosts.txt /etc/hosts
sed -i s/'{HOSTNAME}'/'k8s-master-lb'/g /etc/hosts

service nginx status

if [[ $? != 0 ]]; then

	cat <<EOF
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
EOF
>> ~/.bashrc
	source ~/.bashrc

	sudo apt-get update
	sudo apt-get install -y nginx net-tools
	
	echo "include /etc/nginx/tcp.conf.d/*.conf;" >> /etc/nginx/nginx.conf
	mkdir /etc/nginx/tcp.conf.d

	cp /vagrant/k8s-master-lb/apiserver.conf.txt /etc/nginx/tcp.conf.d/apiserver.conf
	service nginx restart
else
	sed -i s/'#'/''/g /etc/nginx/tcp.conf.d/*.conf
	service nginx restart
fi

