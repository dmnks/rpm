Name:           readin
Version:        1.0
Release:        1
Summary:        Simple read-in test package
Group:		Testing
License:        GPL
BuildArch:	noarch

%description
%{summary}

%prep

%build
cat << EOF > file1
#!/bin/sh
echo yay
EOF
chmod a+x file1
cp file1 file2

cat << EOF > $RPM_READIN_DIR/filelist1.txt
/opt/bin/file1
EOF

cat << EOF > filelist2.txt
/opt/bin/file2
EOF

cat << EOF > %{readindir}/post.sh
#!/bin/sh
echo post
EOF
chmod a+x $RPM_READIN_DIR/post.sh

%install
mkdir -p $RPM_BUILD_ROOT/opt/bin
cp file1 file2 $RPM_BUILD_ROOT/opt/bin/

%post -f post.sh

%files -f filelist1.txt -f filelist2.txt
%defattr(-,root,root,-)
