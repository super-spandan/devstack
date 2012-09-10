This project is a fork of Devstack for easy multinode installation of OpenStack,
OpenVSwitch, and OpenFlow. It supports both OVS VLAN based virtual networking,
and Ryu-based virtual network. Other OpenFlow controllers will be gradually
added.

I will try to keep it in sync with the upstream. If you had any problems, please
file a bug.

This verison is only tested on Ubuntu 12.04. Use other versions at your risk.

# How to install the controller node

In project's root folder, run:

    samples/of/gen-local.sh

This scripts asks for some parameters, and generates the localrc for you. Then,
run devstack to complete the installation:

    ./stack.sh

# How to install a compute node

In project's root folder, run:

    samples/of/gen-local.sh -a

This scripts asks for some parameters, and generates the localrc for you. Then,
run devstack to complete the installation:

    ./stack.sh

# Example Setup

Suppose that we have a 2-node cluster:

    @@@@@@@@@ HOST1 @@@@@@@@    @@@@@@@@ HOST2 @@@@@@@@
    | (192.168.0.100)  eth0|----|eth0 (192.168.0.110) |
    |                      |    |                     |
    |                  eth1|----|eth1                 |
    @@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@

Each node has two interfaces, which are connected as drawn in the figure. eth0's
are used for the control channels, and eth1 is used for connecting VMs. HOST1
will be our controller/network/compute node, and HOST2 will be solely a compute
node.

**NOTE**: It is strongly recommended to use static IPs on the physical
interfaces. If you use DHCP on any desktop distribution (e.g., Ubuntu Desktop),
make sure you uninstall the `network-manager` package.

**NOTE**: If you want to test it on VirtualBox, use the virtual box template
uploaded on [my home page](http://www.cs.toronto.edu/~soheil/devstack-vbox.tbz2)
and also make sure that you have disabled DHCP for vboxnet0
(File/Preferences/Networks).

## Install devstack on HOST1

Run:

    samples/of/gen-local.sh

For our example, answer the question as below:

    Please enter a password (this is going to be used for all services):
    somepassword
    Which interface should be used for vm connection (ie, eth0 eth1 )?
    eth1
    What's the ip address of this machine? [192.168.0.100]
    192.168.0.100
    Would you like to use OpenFlow? ([n]/y)
    n

If you want to have Ryu installed anser the last question by "y".

Now, run `./stack.sh`! If the script runs sucessfully you should be able to
login on horizon (192.168.0.100).

## Install devstack on HOST2

Run:

    samples/of/gen-local.sh -a

For our exmaple, answer the questions as:

    Please enter a password (this is going to be used for all services):
    somepassword
    Which interface should be used for vm connection (ie, eth0 eth1 )?
    eth1
    What's the ip address of this machine? [192.168.0.110]
    192.168.0.110
    Would you like to use OpenFlow? ([n]/y)
    n
    What's the controller's ip address?
    192.168.0.100

If you want to install Ryu, answer 'y' to the OpenFlow question.

# Copyleft

There are two other forks, which I reused code from:
https://github.com/davlaps/devstack/
https://github.com/osrg/devstack/

# Original DevStack Readme

DevStack is a set of scripts and utilities to quickly deploy an OpenStack cloud.

# Goals

* To quickly build dev OpenStack environments in a clean Ubuntu or Fedora environment
* To describe working configurations of OpenStack (which code branches work together?  what do config files look like for those branches?)
* To make it easier for developers to dive into OpenStack so that they can productively contribute without having to understand every part of the system at once
* To make it easy to prototype cross-project features
* To sanity-check OpenStack builds (used in gating commits to the primary repos)

Read more at http://devstack.org (built from the gh-pages branch)

IMPORTANT: Be sure to carefully read `stack.sh` and any other scripts you execute before you run them, as they install software and may alter your networking configuration.  We strongly recommend that you run `stack.sh` in a clean and disposable vm when you are first getting started.

# Devstack on Xenserver

If you would like to use Xenserver as the hypervisor, please refer to the instructions in `./tools/xen/README.md`.

# Versions

The devstack master branch generally points to trunk versions of OpenStack components.  For older, stable versions, look for branches named stable/[release] in the DevStack repo.  For example, you can do the following to create a diablo OpenStack cloud:

    git checkout stable/diablo
    ./stack.sh

You can also pick specific OpenStack project releases by setting the appropriate `*_BRANCH` variables in `localrc` (look in `stackrc` for the default set).  Usually just before a release there will be milestone-proposed branches that need to be tested::

    GLANCE_REPO=https://github.com/openstack/glance.git
    GLANCE_BRANCH=milestone-proposed

# Start A Dev Cloud

Installing in a dedicated disposable vm is safer than installing on your dev machine!  To start a dev cloud:

    ./stack.sh

When the script finishes executing, you should be able to access OpenStack endpoints, like so:

* Horizon: http://myhost/
* Keystone: http://myhost:5000/v2.0/

We also provide an environment file that you can use to interact with your cloud via CLI:

    # source openrc file to load your environment with osapi and ec2 creds
    . openrc
    # list instances
    nova list

If the EC2 API is your cup-o-tea, you can create credentials and use euca2ools:

    # source eucarc to generate EC2 credentials and set up the environment
    . eucarc
    # list instances using ec2 api
    euca-describe-instances

# Customizing

You can override environment variables used in `stack.sh` by creating file name `localrc`.  It is likely that you will need to do this to tweak your networking configuration should you need to access your cloud from a different host.

# RPC Backend

Multiple RPC backends are available. Currently, this
includes RabbitMQ (default), Qpid, and ZeroMQ. Your backend of
choice may be selected via the `localrc`.

Note that selecting more than one RPC backend will result in a failure.

Example (ZeroMQ):

    ENABLED_SERVICES="$ENABLED_SERVICES,-rabbit,-qpid,zeromq"

Example (Qpid):

    ENABLED_SERVICES="$ENABLED_SERVICES,-rabbit,-zeromq,qpid"

# Swift

Swift is not installed by default, you can enable easily by adding this to your `localrc`:

    enable_service swift

If you want a minimal Swift install with only Swift and Keystone you can have this instead in your `localrc`:

    disable_all_services
    enable_service key mysql swift

If you use Swift with Keystone, Swift will authenticate against it. You will need to make sure to use the Keystone URL to auth against.

If you are enabling `swift3` in `ENABLED_SERVICES` devstack will install the swift3 middleware emulation. Swift will be configured to act as a S3 endpoint for Keystone so effectively replacing the `nova-objectstore`.

Only Swift proxy server is launched in the screen session all other services are started in background and managed by `swift-init` tool.

By default Swift will configure 3 replicas (and one spare) which could be IO intensive on a small vm, if you only want to do some quick testing of the API you can choose to only have one replica by customizing the variable `SWIFT_REPLICAS` in your `localrc`.
