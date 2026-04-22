# Installing OpenPBS

> [!NOTE]
> The installation steps described in this README were performed while setting up an all-in-one development environment on a single Linux machine. These steps reflect a local development and evaluation setup and may differ from the procedures required for configuring a production PBS cluster environment.

## Prerequisites
- A Linux PC or VM with Rocky Linux 9.7 installed
- The Linux PC is configured with a hostname that can be resolved via DNS (dnslookup)
- The system is reachable over the network

## Installation

### Installing dependencies for PBS
```bash
sudo dnf install epel-release
sudo crb enable
sudo dnf update
sudo dnf install -y dnf-plugins-core
sudo dnf install -y gcc make rpm-build libtool hwloc-devel libX11-devel libXt-devel libedit-devel libical-devel ncurses-devel perl postgresql-devel postgresql-contrib python3-devel tcl-devel tk-devel swig expat-devel openssl-devel libXext libXft autoconf automake gcc-c++ cjson python312 python3.12-devel cjson-devel git
sudo dnf install -y expat libedit postgresql-server postgresql-contrib python3 sendmail sudo tcl tk libical
```

### Preparing an Environment to Build OpenPBS with Python 3.12
On Rocky Linux 9, both Python 3.9 and Python 3.12 are installed by default, with Python 3.9 configured as the system default.
If OpenPBS is built without any additional configuration, it will therefore use Python 3.9 internally. However, the QRMI Python module requires Python 3.11 or later, which makes the default setup incompatible.
For this reason, it is necessary to prepare the environment so that OpenPBS uses Python 3.12 before building and installing OpenPBS. This ensures compatibility with QRMI and allows PBS hooks and related components to correctly import and use the QRMI Python modules.

```bash
mkdir -p $HOME/pbs-build-python/bin
ln -sf /usr/bin/python3.12 $HOME/pbs-build-python/bin/python3
ln -sf /usr/bin/python3.12-config $HOME/pbs-build-python/bin/python3-config
```

### Building OpenPBS
The latest stable release of OpenPBS available on GitHub, v23.06.06, fails to build when configured to use Python 3.12.
This issue is due to incomplete support for Python 3.12 in that release.
Support for Python 3.12 and later has been added in subsequent commits to the main branch of the OpenPBS repository.
Therefore, in this setup, we use the latest source code from the main branch instead of the v23.06.06 release to ensure proper compatibility with Python 3.12 and with QRMI’s Python requirements.

```bash
git clone https://github.com/openpbs/openpbs
cd openpbs
./autogen.sh
./configure --with-python=$HOME/pbs-build-python --prefix=/opt/pbs
make 2>&1 | tee ./log_build
sudo make install 2>&1 | tee ./log_install
```

### Create PBS configuration file
Copy [pbs.conf](../pbs/pbs.conf) to /etc/pbs.conf. Replace PBS_SERVER value with your hostname. The PBS_SERVER value must be set to a fully qualified hostname (hostname + domain name).
Do not use localhost, 127.0.0.1, or a raw IP address.
The specified hostname must be registered in DNS and resolvable via name lookup.
In other words, running the following command should successfully resolve the hostname to an IP address:
```bash
nslookup <hostname>
```
Ensuring proper DNS name resolution is required for correct OpenPBS operation and inter-component communication.

### Configure PBS
```bash
sudo /opt/pbs/libexec/pbs_postinstall
sudo chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp
sudo su -
. /etc/profile.d/pbs.sh
exit
sudo rm /etc/rc.d/init.d/pbs
```

The following initialization script must be executed for each user who will use PBS.
```bash
. /etc/profile.d/pbs.sh
sudo rm /etc/rc.d/init.d/pbs
```

### Start PBS
```bash
sudo systemctl --now enable pbs
```

### Verify installation
```bash
qstat -B
qmgr -c 'p s'
sudo -i qmgr -c "print node `hostname -s`"
```
If an error occurs, use the following commands to identify the root cause and resolve the issue.
```bash
sudo systemctl status pbs
less /var/spool/pbs/server_logs/`ls -t /var/spool/pbs/server_logs/ | head -1`
```

You can now submit PBS job. 

Create a simple job with name "hello.sh".
```script
#!/bin/bash
#PBS -N MyFirstJob
#PBS -l select=1:ncpus=1:mem=2gb
#PBS -l walltime=00:10:00
#PBS -j oe
#PBS -m bae

# Change to the directory where the job was submitted
cd $PBS_O_WORKDIR

# Your actual commands
env
echo "Starting job on $(hostname)"
sleep 10
echo "Job finished at $(date)"
```

And submit this job.
```bash
qsub hello.sh
```

MyFirstJob.o1 will be created when job is finished.
