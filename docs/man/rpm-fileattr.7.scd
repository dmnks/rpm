RPM-FILEATTR(7)

# NAME
*rpm-fileattr* - RPM file attributes and dependency generation system

# SYNOPSIS

# DESCRIPTION

RPM uses a pluggable dependency generation system that automatically detects and
adds dependency information to packages during the build process. This works by
scanning files in the buildroot and assigning them logical labels, called _file
attributes_. Specialized executables, called _generators_, are then invoked for
each attribute and its files in order to produce a list of dependencies for the
package.

This system is meant to complement the explicit *Requires* and *Provides* tags
in *rpm-spec*(5) files.

# FILE ATTRIBUTES

File attributes are configurable labels that represent files from a specific
domain or with a shared purpose, such as ELF binaries, executable scripts or
system font configuration. RPM uses these labels in order to narrow down the
list of files that have to be passed to generators and thus improve the package
build performance.

A file attribute is introduced with a predetermined set of *rpm-macros*(7) that
start with the prefix *%\_\_NAME*, where *NAME* is the name of the file
attribute. These macros are stored in an *rpm-macrofile*(5) with the same name,
followed by the _.attr_ suffix and placed into the directory specified by the
*%{\_fileattrs}* macro, typically _/usr/lib/rpm/fileattrs/_.

The following file attribute macros are recognized:

```
%__NAME_path
%__NAME_magic
%__NAME_flags
%__NAME_exclude_path
%__NAME_exclude_magic
%__NAME_exclude_flags
```

# GENERATORS
## External Generators (DEPRECATED)
## Protocols
## Parametric Macros

# SPEC-LOCAL FILE ATTRIBUTES AND GENERATORS
# TROUBLESHOOTING
# EXAMPLES
