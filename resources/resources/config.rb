# Cookbook Name:: k2http
#
# Resource:: config
#

actions :add, :remove, :register, :deregister
default_action :add

attribute :user, :kind_of => String, :default => "k2http"
attribute :logdir, :kind_of => String, :default => "/var/log/k2http"