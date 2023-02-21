Name: hello
Version: 1.0
Release: 1
Group: Testing
License: GPL
Summary: Simple rpm demonstration.

Source0: hello-1.0.tar.gz
Patch0: hello-1.0-install.patch
Patch1: hello-1.0-modernize.patch
Patch2: hello-1.0-modernize2.patch
Patch3: hello-1.0-modernize3.patch

%description
Simple rpm demonstration.

%prep
%setup -q
%patch0 -p1 -b .install
%patch1 -p1 -b .modernize
#%patch2 -p1 -b .modernize2
#%patch3 -p1 -b .modernize3

%changelog
