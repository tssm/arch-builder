This is how I like to Arch Linux.

# Usage

Run `create-box`. It will ask a series of questions in
order the create a new virtual machine suitable to install Arch
Linux. Requires VirtualBox.

Once the machine is created you need to boot it with an [Arch
Linux image][arch] attached to an optical drive and then:

```bash
curl -LO https://github.com/tssm/arch-builder/archive/v3.1.tar.gz
tar -zxvf v3.1.tar.gz
cd arch-builder-3.0
# Edit the env file as desired
./build new
```

This will create the necessary partitions, prepare the filesystems
and install a **minimum** list of packages. Don't expect the
complete `base` group to be installed. I am pretty opinionated on
it. Read the script to figure which packages will be installed.

The `build vm` command is what I run on new Arch
Linux instances created by a cloud provider. It helps to set up
some things and also romoves packages that I don't want. It
expects a `key.pub` file on your home.

[arch]: https://www.archlinux.org/download/
