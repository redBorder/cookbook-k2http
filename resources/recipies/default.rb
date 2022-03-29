#
# Cookbook Name:: k2http
# Recipe:: default
#
# redborder
#
#

k2http_config "config" do
  name node["hostname"]
  action :add
end