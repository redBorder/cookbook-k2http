# Cookbook:: k2http
# Recipe:: default
# Copyright:: 2024, redborder
# License:: Affero General Public License, Version 3

k2http_config 'config' do
  name node['hostname']
  action :add
end
