Vagrant.configure("2") do |config|
	config.ssh.insert_key = false

	config.vm.box = "archlinux/archlinux"

	config.vm.provision "shell", inline: "cd /vagrant && ./build vm && ./build postgresql"
end
