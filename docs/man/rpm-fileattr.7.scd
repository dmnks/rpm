RPM-FILEATTR(7)

# NAME
*rpm-fileattr* - RPM file attribute system

# SYNOPSIS

# DESCRIPTION

RPM allows for registering _file attributes_ (labels assigned to files in the
buildroot) and the associated _file handlers_ (parametric macros or executables)
to be used for domain-specific tasks when building packages. This mechanism is
currently only used for automatic dependency generation, which is described in
*rpm-autodeps*(7).

# FILE ATTRIBUTES

File attributes are labels that represent file types, such as ELF executables,
or broader domains, such as language-specific source files. These are distinct
from the file attributes stored on the filesystem, and are only kept in memory
during the package build process. Their purpose is to simplify the writing of
file handlers by them not having to implement the classification logic, as well
as to improve build performance by not having to pass every file through every
handler.

RPM assigns these attributes by scanning the buildroot and matching the files
against a set of _rules_ defined for every known attribute. If a file matches
either of the inclusion and none of the exclusion rules (see below), then the
file is said to _have_ the attribute in question. Every file may have any number
of attributes and every attribute may be assigned to any number of files.

A file attribute is introduced with at least one of the following macros:

```
%__NAME_path
%__NAME_magic
```

The values of both macros are interpreted as extended regular expressions (RE).
The path RE is matched against the packaged path, without *%{buildroot}* (for
example, */bin/bash*). The magic RE is matched against the result of libmagic
classification (see *file*(1) and *magic*(5) for details) and possibly the
*FILECLASS* tag stored in the package (see *--fileclass* in *rpm*(8) for
details).

CONTINUE HERE

See the *%\_\_NAME\_flags* macro for how to control which of the two inclusion
and exclusion rules should be used and when.

Flags allow for fine-tuning the inclusion and exclusion rule matching. They are
specified with the following macros, which take a comma-separated list of flag
names:

```
%__NAME_flags
%__NAME_exclude_flags
```

The following flags are currently supported:

- *exeonly*: require executable bit set
- *magic_and_path*: require both magic and pattern to match

These macros are stored in an *rpm-macrofile*(5) with the same name, followed by
the _.attr_ suffix and placed into the directory specified by the
*%{\_fileattrs}* macro, typically _/usr/lib/rpm/fileattrs/_.

# FILE HANDLERS
# EXAMPLES
