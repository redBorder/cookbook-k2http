%global cookbook_path /var/chef/cookbooks/k2http

Name: cookbook-k2http
Version: %{__version}
Release: %{__release}%{?dist}
BuildArch: noarch
Summary: k2http cookbook to install and configure it in redborder environments

License: AGPL 3.0
URL: https://github.com/redBorder/cookbook-nginx
Source0: %{name}-%{version}.tar.gz

%description
%{summary}

%prep
%setup -qn %{name}-%{version}

%build

%install
mkdir -p %{buildroot}%{cookbook_path}
cp -f -r  resources/* %{buildroot}%{cookbook_path}
chmod -R 0755 %{buildroot}%{cookbook_path}
install -D -m 0644 README.md %{buildroot}%{cookbook_path}/README.md

%pre

%post
case "$1" in
  1)
    # This is an initial install.
    :
  ;;
  2)
    # This is an upgrade.
    su - -s /bin/bash -c 'source /etc/profile && rvm gemset use default && env knife cookbook upload k2http'
  ;;
esac

%files
%defattr(0755,root,root)
%{cookbook_path}
%attr(0644,root,root)
%{cookbook_path}/README.md

%doc

%changelog
* Thu Feb 03 2022 Vicente Mesa <vimesa@redborder.com> - 0.0.1
- first spec version