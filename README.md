This is how I like to Arch Linux.

# Usage

Run `sh create-box.sh`. It will ask a series of questions in
order the create a new virtual machine suitable to install Arch
Linux. Requires VirtualBox.

Once the machine is created you need to boot it with an [Arch
Linux image][arch] attached to an optical drive and then:

```bash
curl -LO https://raw.githubusercontent.com/tssm/arch-builder/master/bin/install.sh
sh install.sh
```

This will create the necessary partitions, prepare the filesystems
and install a **minimum** list of packages. Don't expect the
complete `base` group to be installed. I am pretty opinionated on
it. Read `bin/install.sh` to figure which packages will be
installed.

After it the script will leave you on a `chroot` environment. To
finish the setup you must do the following:

```bash
curl -LO https://github.com/tssm/arch-builder/archive/v1.1.1.tar.gz
tar -zxvf v1.1.1.tar.gz
cd arch-builder-1.1.1
make development
```

This will finish the Arch Linux set up and also will make the
necessary changes to run the machine from Vagrant so you can
expect all the required Vagrant defaults to be set.

The `make production` command is what I run on new Arch Linux
instances created by [OVH][ovh]. It helps to set up some things
and also romoves packages that I don't want. It expects a
`key.pub` file on your home.

[arch]: https://www.archlinux.org/download/
[ovh]: https://www.ovh.com
