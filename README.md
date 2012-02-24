Description
===========

*NOTE*: This is a fork of the [Opscode DRBD cookbook](https://github.com/opscode/cookbooks/tree/master/drbd) that adds additional configuration parameters (see the attributes below).

Installs and configures the Distributed Replicated Block Device (DRBD) service for mirroring block devices between a pair of hosts. Right now it simply works in pairs, multiple hosts could be supported with a few small changes.

The `drbd` cookbook does not partition drives. It will format partitions given a filesystem type, but it does not explicitly depend on the `xfs` cookbook if you want that type of filesystem, but you can put it in your run list and set the node['drbd']['fs_type'] to 'xfs' or 'ext4' or whatever. \

*side note: you can list your partitions with:* `fdisk -l`

Requirements
============
Platform
--------
Tested with Ubuntu 10.04 and 10.10. You must have the 'linux-server' package and 'linux-headers-server' kernel installed to properly support the drbd module.

Recipes
=======
default
-------
Installs drbd but does no configuration.

pair
----
Given a filesystem and a partner host, configures block replication between the hosts. The master will claim the primary, format the filesystem and mount the partition. The slave will simply mirror without mounting. **It currently takes 2 chef-client runs to ensure the pair is synced properly.**

Attributes
==========
The required attributes are

* `node['drbd]['resource']` - The name for the DRBD resource. Defaults to "pair"
* `node['drbd]['internal_ip']` - Host's IP Address. You may provide a value for this attribute if your host has multiple addresses, and you wish to specify which one is used. Otherwise, Chef will use the IP address of the node (`node.ipaddress`).
* `node['drbd]['remote_ip']` - Remote host's IP Address. Similar to `internal_ip`, you may specify this if you want to control which IP address is used by the remote host. The default value is that of the node (`node.ipaddress`)
* `node['drbd]['remote_host']` - Remote host to pair with.
* `node['drbd]['disk']` - Disk partition to mirror.
* `node['drbd]['mount']` - Mount point to mirror.
* `node['drbd]['fs_type']` - Disk format for the mirrored disk, defaults to `ext3`.
* `node['drbd]['master']` - Whether this node is master between the pair, defaults to `false`.
* `node['drbd]['usage_count']` - Whether or not to participate in usage statistics. Defaults to "yes".
* `node['drbd]['protocol']` - The synchronization protocol to use. Defaults to "C". For more information, see the docs for [DRBD Replication Modes](http://www.drbd.org/users-guide-emb/s-replication-protocols.html)
* `node['drbd]['sync_rate']` - That rate at which to sync. Defaults to "40M"

Roles
=====
There are a pair of example roles `drbd-pair.rb` and `drbd-pair-master.rb` with the cookbook source.

License and Author
==================

Author: Matt Ray (<matt@opscode.com>)

Copyright 2011, Opscode, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
