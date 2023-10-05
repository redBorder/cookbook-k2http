#Cookbook Name:: k2http
#
# Provider:: config
#

include K2http::Helper

action :add do
  begin
    user = new_resource.user
    logdir = new_resource.logdir

    dnf_package "k2http" do
      action :upgrade
      flush_cache [:before]
    end

    user user do
      action :create
      system true
    end

    directory logdir do
      owner user
      group group
      mode 0770
      action :create
    end

    directory "/etc/k2http" do
      owner user
      group group
      mode 0755
    end

    # generate k2http config
    template "/etc/k2http/config.yml" do
      source "k2http_config.yml.erb"
      owner user
      group user
      mode 0644
      cookbook "k2http"
      notifies :restart, "service[k2http]"
    end

    service "k2http" do
      service_name "k2http"
      ignore_failure true
      supports :status => true, :reload => true, :restart => true, :enable => true
      action [:start, :enable]
    end

    Chef::Log.info("K2http cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end

end

action :remove do
  begin

    service "k2http" do
      service_name "k2http"
      ignore_failure true
      supports :status => true, :enable => true
      action [:stop, :disable]
    end

    Chef::Log.info("K2http cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do #Usually used to register in consul
  begin
    if !node["k2http"]["registered"]
      query = {}
      query["ID"] = "k2http-#{node["hostname"]}"
      query["Name"] = "k2http"
      query["Address"] = "#{node["ipaddress"]}"
      query["Port"] = 443
      json_query = Chef::JSONCompat.to_json(query)

      execute 'Register service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
        action :nothing
      end.run_action(:run)

    end
    Chef::Log.info("k2http service has been registered in consul")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :deregister do #Usually used to deregister from consul
  begin
    if node["k2http"]["registered"]
      execute 'Deregister service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/deregister/k2http-#{node["hostname"]} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.set["k2http"]["registered"] = false
    end
    Chef::Log.info("k2http service has been deregistered from consul")
  rescue => e
    Chef::Log.error(e.message)
  end
end
