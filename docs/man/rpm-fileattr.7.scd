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




# GENERATORS
## External Generators (DEPRECATED)
## Protocols
## Parametric Macros

# SPEC-LOCAL FILE ATTRIBUTES AND GENERATORS
# TROUBLESHOOTING
# EXAMPLES
