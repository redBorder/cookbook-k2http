# Cookbook:: k2http
# Provider:: config

include K2http::Helper

action :add do
  begin
    user = new_resource.user
    logdir = new_resource.logdir

    # k2http now runs the kafka2x binary, /etc/systemd/system/k2http.service overrides the old package unit
    dnf_package 'kafka2x' do
      action :upgrade
      notifies :restart, 'service[k2http]', :delayed
    end

    # kafka2x ships its own unit, it would consume the same group as k2http
    service 'kafka2x' do
      service_name 'kafka2x'
      ignore_failure true
      supports status: true, enable: true
      action [:stop, :disable]
    end

    execute 'create_user' do
      command "/usr/sbin/useradd -r #{user} -s /sbin/nologin"
      ignore_failure true
      not_if "getent passwd #{user}"
    end

    directory logdir do
      owner user
      group group
      mode '0770'
      action :create
    end

    directory '/etc/k2http' do
      owner user
      group group
      mode '0755'
    end

    # generate k2http config
    template '/etc/k2http/config.json' do
      source 'k2http_config.json.erb'
      owner user
      group user
      mode '0644'
      cookbook 'k2http'
      notifies :restart, 'service[k2http]'
    end

    file '/etc/k2http/config.yml' do
      action :delete
    end

    execute 'k2http_daemon_reload' do
      command 'systemctl daemon-reload'
      action :nothing
    end

    template '/etc/systemd/system/k2http.service' do
      source 'k2http.service.erb'
      owner 'root'
      group 'root'
      mode '0644'
      cookbook 'k2http'
      variables(user: user)
      notifies :run, 'execute[k2http_daemon_reload]', :immediately
      notifies :restart, 'service[k2http]'
    end

    service 'k2http' do
      service_name 'k2http'
      ignore_failure true
      supports status: true, reload: true, restart: true, enable: true
      action [:start, :enable]
    end

    Chef::Log.info('K2http cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    service 'k2http' do
      service_name 'k2http'
      ignore_failure true
      supports status: true, enable: true
      action [:stop, :disable]
    end

    Chef::Log.info('K2http cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do
  begin
    unless node['k2http']['registered']
      query = {}
      query['ID'] = "k2http-#{node['hostname']}"
      query['Name'] = 'k2http'
      query['Address'] = "#{node['ipaddress']}"
      query['Port'] = 443
      json_query = Chef::JSONCompat.to_json(query)

      execute 'Register service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['k2http']['registered'] = true
      Chef::Log.info('k2http service has been registered in consul')
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :deregister do
  begin
    if node['k2http']['registered']
      execute 'Deregister service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/deregister/k2http-#{node['hostname']} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['k2http']['registered'] = false
    end
    Chef::Log.info('k2http service has been deregistered from consul')
  rescue => e
    Chef::Log.error(e.message)
  end
end
