Name:           reloc2
Version:        1.0
Release:        1
Summary:        Testing relocation behavior with prefix ownership
License:        GPL
Prefix:         /
BuildArch:      noarch

%description
%{summary}.

%install
mkdir -p $RPM_BUILD_ROOT/foo
touch $RPM_BUILD_ROOT/foo/bar

%files
%{prefix}

%changelog
* Wed Mar 13 2024 root
- 
