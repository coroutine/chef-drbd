#
# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: drbd
# Recipe:: pair
#
# Copyright 2011, Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/shell_out'

include_recipe "drbd"

resource = node['drbd']['resource'] || "pair"

if node['drbd']['remote_host'].nil? || node['drbd']['remote_ip'].nil?
  Chef::Application.fatal! "You must define a ['drbd']['remote_host'] and a ['drbd']['remote_ip'] to use the drbd::pair recipe."
end

if node['drbd']['remote_host']
  remote = search(:node, "name:#{node['drbd']['remote_host']}")[0]
end

template "/etc/drbd.d/#{resource}.res" do
  source "res.erb"
  variables(
    :resource => resource,
    :remote_ip => node['drbd']['remote_ip'] || remote.ipaddress,
    :internal_ip => node['drbd']['internal_ip'] || node.ipaddress
  )
  owner "root"
  group "root"
  action :create
end

template "/etc/drbd.d/global_common.conf" do
  source "global_common.conf.erb"
  variables(
    :usage_count => node['drbd']['usage_count'],
    :protocol => node['drbd']['protocol'],
    :rate => node['drbd']['sync_rate']
  )
  owner "root"
  group "root"
  action :create
end

# Make sure drbd is running
service "drbd" do
  action [:enable, :start]
end

#first pass only, initialize drbd
execute "drbdadm create-md #{resource}" do
  subscribes :run, resources(:template => "/etc/drbd.d/#{resource}.res")
  notifies :restart, resources(:service => "drbd"), :immediate
  only_if do
    cmd = Chef::ShellOut.new("drbd-overview")
    overview = cmd.run_command
    Chef::Log.info overview.stdout
    overview.stdout.include?("drbd not loaded")
  end
  action :nothing
end

#claim primary based off of node['drbd']['master']
execute "drbdadm -- --overwrite-data-of-peer primary all" do
  subscribes :run, resources(:execute => "drbdadm create-md #{resource}")
  only_if { node['drbd']['master'] && !node['drbd']['configured'] }
  action :nothing
end

#You may now create a filesystem on the device, use it as a raw block device
execute "mkfs -t #{node['drbd']['fs_type']} #{node['drbd']['dev']}" do
  subscribes :run, resources(:execute => "drbdadm -- --overwrite-data-of-peer primary all")
  only_if { node['drbd']['master'] && !node['drbd']['configured'] }
  action :nothing
end

directory node['drbd']['mount'] do
  only_if { node['drbd']['master'] && !node['drbd']['configured'] }
  action :create
end

#mount -t xfs -o rw /dev/drbd0 /shared
mount node['drbd']['mount'] do
  device node['drbd']['dev']
  fstype node['drbd']['fs_type']
  only_if { node['drbd']['master'] && node['drbd']['configured'] }
  action :mount
end

#hack to get around the mount failing
ruby_block "set drbd configured flag" do
  block do
    node['drbd']['configured'] = true
  end
  subscribes :create, resources(:execute => "mkfs -t #{node['drbd']['fs_type']} #{node['drbd']['dev']}")
  action :nothing
end
