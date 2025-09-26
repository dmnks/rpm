Name:           shebang
Version:        0.1
Release:        1
Summary:        Testing shebang dependency generation
Group:          Testing
License:        GPL
BuildArch:	noarch

%description
%{summary}

%install
mkdir -p %{buildroot}/bin
cat << EOF > %{buildroot}/bin/shebang.frob
hello
EOF

%files
/bin/shebang.frob
