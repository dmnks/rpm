RPM-FILEATTR(7)

# NAME
*rpm-fileattr* - RPM file attributes and dependency generation system

# SYNOPSIS

# DESCRIPTION

RPM uses a plug-in dependency generator interface coupled with a file classifier
to automatically detect dependencies in packages during the build process. This
system relies on specialized executables called _generators_ which do the heavy
lifting of inspecting files in their area of expertise and extracting dependency
information from them, and is intended to complement the explicit *Requires* and
*Provides* tags in *rpm-spec*(5) files.

# FILE ATTRIBUTES

File attributes are logical labels assigned by RPM to files in the buildroot.
They represent specific file types or domains, such as ELF binaries, executable
scripts or font configuration. RPM uses these attributes in order to narrow down
the list of files that have to be passed to generators, improving the package
build performance.

A file attribute is introduced with a predetermined set of *rpm-macros*(7) that
start with the prefix *%\_\_NAME*, where *NAME* is the name of the file
attribute. These macros can be categorized as _rules_, _flags_ and _options_,
and are described in the subsections below.

## Rules

Rule macros are extended regular expressions (RE) used by RPM to match files
against. If a file matches either of the inclusion and none of the exclusion
rules, then the file is said to _have_ the attribute in question.

The following inclusion and exclusion macros are currently supported:

```
%__NAME_path
%__NAME_magic
%__NAME_exclude_path
%__NAME_exclude_magic
```

The path REs are matched against the packaged path, without the *%{buildroot}*
prefix. The magic REs are matched against the result of libmagic classification
(see *file*(1) and *magic*(5) for details) and possibly the *FILECLASS* tag
stored in the package (see *--fileclass* in *rpm*(8) for details).

See the *%\_\_NAME\_flags* macro for how to control which of the two inclusion
rules should be used and when.

## Flags

## Options




These macros are stored in an *rpm-macrofile*(5) with the same name, followed by
the _.attr_ suffix and placed into the directory specified by the
*%{\_fileattrs}* macro, typically _/usr/lib/rpm/fileattrs/_.

# GENERATORS
## External Generators (DEPRECATED)
## Protocols
## Parametric Macros

# SPEC-LOCAL FILE ATTRIBUTES AND GENERATORS
# TROUBLESHOOTING
# EXAMPLES
