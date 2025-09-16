RPM-FILEATTR(7)

# NAME
*rpm-fileattr* - RPM file attribute system

# SYNOPSIS

# DESCRIPTION

File attributes are simple labels that RPM gives to files in the buildroot based
on a set of matching rules. These attributes are distinct from the standard file
metadata on disk and are only kept in memory during package builds.

Currently, file attributes can be associated with dependency generators




They can be
associated with specialized macros, called _file handlers_, which RPM uses to
perform domain-specific tasks, such as generating dependency information.




They can be
defined in a dedicated *rpm-macrofile*(5) or directly in an *rpm-spec*(5) file.

# DEFINING
# EFFECTS
# EXAMPLES
