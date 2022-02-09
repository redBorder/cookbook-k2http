# Cookbook Name:: k2http
#
# Resource:: config
#

actions :add, :remove, :register, :deregister
default_action :add

attribute :user, :kind_of => String, :default => "k2http"
attribute :zk_hosts, :kind_of => String
attribute :mse_nodes, :kind_of => Array, :default => []
