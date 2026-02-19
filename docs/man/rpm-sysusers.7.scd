RPM-SYSUSERS(7)

# NAME

*rpm-sysusers* - RPM native allocation of users and groups through *sysusers.d*(5)

# SYNOPSIS

## Declaration

*%{\_sysusersdir}*_/\*.conf_++
*%{add_sysuser *_LINE_*}*

## Line format

*u* _UNAME_ _UID_ _GECOS_ _HOMEDIR_ _SHELL_++
*u* _UNAME_ _UID_*:*_GID_ _GECOS_ _HOMEDIR_ _SHELL_++
*u* _UNAME_ _FILE_ _GECOS_ _HOMEDIR_ _SHELL_++
*g* _GNAME_ _GID_++
*g* _GNAME_ _FILE_++
*m* _UNAME_ _GNAME_++
*#* _COMMENT_

## Notes

- Suffix *u* with an exclamation mark (*!*) to create a fully locked account
  (recommended)
- Use a dash (*-*) as _UID_/_GID_ for automatic number allocation (recommended)
- _FILE_ is an absolute path to a file whose UID/GID should be used
- _LINE_ uses *Line format* with the fields passed as macro arguments

# DESCRIPTION

RPM has native support for declarative user and group creation by integrating
with the *sysusers.d*(5) format (introduced by systemd). Packagers only need to
drop one or more files to _/usr/lib/sysusers.d/_ and RPM will handle the rest,
such as dependency generation and the invocation of *systemd-sysusers*(8) during
the build and installation, respectively.

Vendors on non-systemd platforms can enable the feature by shipping any missing
tools and configuring RPM accordingly (see *PORTABILITY* for details).

Note that for certain types of systemd services (such as transient or socket
activated), it may be possible to avoid package level user/group allocation
altogether by using _Dynamic Users_ (see *DynamicUser=* in *systemd.exec*(5) and
the URL in *SEE ALSO* for details).

Added: 4.19.0

# DEPENDENCIES

Packaged *sysusers.d*(5) files generate virtual provides for the users and/or
groups they define. Similarly, any non-root ownership defined with *%attr()* or
*%defattr()* in an *rpm-spec*(5) file generates virtual requires for the named
users and/or groups. Both dependencies complement each other to ensure correct
installation when a package relies on a user/group from another package.

Explicit group membership (the *m* sysusers.d directive) will also generate
virtual requires for both the user and the group name in the originating
package.

For more details on the mechanism itself, see *rpm-dependency-generators*(7).

# LIMITATIONS

Currently, RPM only supports the following sysusers.d directives:

- *u* and *g* (Added: 4.19.0)
- *m* (Added: 4.20.0)
- *u!* (Added: 4.20.1)

Other directives, if used, will be ignored. If such are needed, the package has
to call *systemd-sysusers*(8) with the correct arguments manually.

# PORTABILITY

RPM provides a number of tunables to enable vendors and packagers to implement
the declarative user and group integration on platforms that do not ship with
the default systemd tooling. Note, however, that some tunables may need tweaking
even on platforms with systemd.

## Vendors

*%\_\_systemd_sysusers* _PATH_
	Path to the *systemd-sysusers*(8) executable or a compatible program.

	On systemd native platforms, set _PATH_ to the *systemd-sysusers*(8)
	program, typically at _/usr/bin/systemd-sysusers_. Note that the program
	may also be shipped by a standalone package with no systemd dependencies
	(such as *systemd-standalone-sysusers* on Fedora Linux) which makes it
	useful in containers or similar environments.

	RPM ships with a replacement shell script that calls the standard UNIX
	tools such as *useradd*(8) or *groupadd*(8) for account creation. The
	script is installed at *%{\_rpmconfigdir}*_/sysusers.sh_ and can be used
	on platforms where the original program is not available.

	On platforms without the standard UNIX account tools, a custom script or
	program can be written, which must:

	- Process *sysusers.d*(5) lines on standard input
	- Create or modify users and groups accordingly
	- Never delete any users or groups
	- Handle the *--root* and *--replace* options like the original program
	- Avoid changing the host if *--root* is used

*%\_sysusersdir* _PATH_
	Path to the drop-in directory where packages are supposed to install the
	*sysusers.d*(5) files. Defaults to _/usr/lib/sysusers.d_.

## Packagers

*%add_sysusers* _LINE_
	Interpret _LINE_ as if written in a *sysusers.d*(5) file. _LINE_ denotes
	the individual fields passed as macro arguments.

	This macro can be defined in an *rpm-spec*(5) file, in the context of a
	(sub)package. Its purpose is to allow declaring users and groups without
	having to ship any *sysusers.d*(5) files on non-systemd platforms.

# COMPATIBILITY

## Vendors

By default, the generated virtual requires are _hard_ dependencies. This can be
problematic when upgrading an existing distribution to RPM 4.19, however, so it
is possible to weaken these requires into recommends, by setting
*%\_use_weak_usergroup_deps* to *1* in the *rpmbuild-config*(5).

# TECHNICAL DETAILS
## Encoding

RPM will generate any combination of the following virtual provides based on,
and attached to, the packaged *sysusers.d*(5) file(s):

*user(*_uname_*) = *_base64_++
*group(*_gname_*)*[* = *_base64_]++
*groupmember(*_uname_*/*_gname_*) = *_base64_

_uname_ and _gname_ are the respective user and group name. _base64_ is a base64
encoded representation of the given sysusers.d line, with the input *\\0*-padded
as needed, in order to avoid the base64 native *=* padding in the output, which
is illegal in an EVR string.

For example, the following sysusers.d line:

```
u dnsmasq - "Dnsmasq DHCP and DNS server" /var/lib/dnsmasq
```

would emit the following provides attached to the originating file:

```
user(dnsmasq) = dSBkbnNtYXNxIC0gIkRuc21hc3EgREhDUCBhbmQgRE5TIHNlcnZlciIgL3Zhci9saWIvZG5zbWFzcQAA
group(dnsmasq)
```

As *systemd-sysusers*(8) implicitly creates a matching group for any created
users, the group provides does not have an EVR here. Only explicitly created
groups will have the encoded sysusers.d line as an EVR.

Lines adding users to groups, such as:

```
m klangd klong
```

will create a provides:

```
groupmember(klangd/klong) = bSBrbGFuZ2Qga2xvbmcA
```

They will also create two requires (or recommends if
*%\_use_weak_usergroup_deps* is set to *1*):

```
group(klong)
user(klangd)
```

to make sure the packages creating the user and group are installed first.

## Decoding

When RPM installs a package with virtual provides as described in *ENCODING*, it
decodes their EVR strings back from base64 to the original sysusers.d lines and
groups them by their source file. Then, it executes the *systemd-sysusers*(8)
program once for each source file, with *--replace* pointing to the path of the
source file when installed, and passes the decoded lines pertaining to that file
on standard input. The program then creates new, or modifies existing, users and
groups on the system, according to those lines.

Since the above process happens before the payload is unpacked to disk, packages
can ship files owned by their own users and groups.

Note that the packaged *sysusers.d*(5) files, if any, are installed as normal,
but do not participate in the user/group creation itself. They simply serve as
static definition files for reconstructing */etc/passwd* and */etc/group* later,
as per *sysusers.d*(5).

# TROUBLESHOOTING

*rpm -q *{*--provides*|*--requires*} _PACKAGE_NAME_ *| grep
'^\\(user(\\|group(\\|groupmember(\\)'*
	Display the virtual user/group/groupmember provides/requires of
	_PACKAGE_NAME_.

*rpm -q --queryformat '[%{SYSUSERS}\\n]' *_PACKAGE_NAME_
	Display the original sysusers.d lines decoded from the virtual provides
	of _PACKAGE_NAME_ by using *rpm-queryformat*(7).

# EXAMPLES

## Example 1. Packaging a sysusers.d(5) file

Consider a _dnsmasq.spec_ file with the following contents (irrelevant parts
ellipsized or omitted):

```
%install
mkdir -p ${RPM_BUILD_ROOT}/%{_var}/lib/dnsmasq
mkdir -p ${RPM_BUILD_ROOT}/%{_sysusersdir}
cat << EOF > ${RPM_BUILD_ROOT}/%{_sysusersdir}/dnsmasq.conf
u dnsmasq - "Dnsmasq DHCP and DNS server" /var/lib/dnsmasq
EOF
[...]

%files
%dir %attr(0755,root,dnsmasq) %{_var}/lib/dnsmasq
%{_sysusersdir}/dnsmasq.conf
[...]
```

When the package is built, it will contain the following requires and provides:

```
$ rpm -qp --requires /path/to/dnsmasq.rpm
group(dnsmasq)
[...]
$ rpm -qp --provides /path/to/dnsmasq.rpm
group(dnsmasq)
user(dnsmasq) = dSBkbnNtYXNxIC0gIkRuc21hc3EgREhDUCBhbmQgRE5TIHNlcnZlciIgL3Zhci9saWIvZG5zbWFzcQAA
[...]
```

Finally, when the package is installed, RPM will create the *dnsmasq* user and
group automatically, and the _/var/lib/dnsmasq_ directory installed by the
package itself will be owned by that group as per the spec file:

```
$ getent passwd dnsmasq
dnsmasq:x:999:999:Dnsmasq DHCP and DNS server:/var/lib/dnsmasq:/usr/sbin/nologin
$ getent group dnsmasq
dnsmasq:x:999:
$ stat -c '%G:%g' /var/lib/dnsmasq
dnsmasq:999
```

The original *sysusers.d*(5) file will be installed as normal:

```
$ rpm -ql dnsmasq | grep sysusers
/usr/lib/sysusers.d/dnsmasq.conf
$ cat /usr/lib/sysusers.d/dnsmasq.conf
u dnsmasq - "Dnsmasq DHCP and DNS server" /var/lib/dnsmasq
```

## Example 2. Declaring a sysusers.d line manually

Consider a _dnsmasq.spec_ file with the following contents starting just below
the preamble block (irrelevant parts ellipsized or omitted):

```
%{add_sysuser u dnsmasq - "Dnsmasq DHCP and DNS server" /var/lib/dnsmasq}
[...]

%files
%dir %attr(0755,root,dnsmasq) %{_var}/lib/dnsmasq
[...]
```

Building and installing this package will have the same effect as described in
*Example 1*. The only difference is that, in this example, no *sysusers.d*(5)
file is packaged or installed.

# SEE ALSO

*rpm*(8),
*rpmbuild-config*(5),
*rpm-spec*(5),
*rpm-scriptlets*(7),
*rpm-dependency-generators*(7),
*sysusers.d*(5),
*systemd-sysusers*(8),
*systemd.exec*(5),
*useradd*(8),
*groupadd*(8)

*https://0pointer.net/blog/dynamic-users-with-systemd.html*
