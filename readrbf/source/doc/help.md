% readrbf

# NAME
readrbf - read a record-based file and convert it to a known format

# SYNOPSIS
readrbf -i file - l layout [-o format] [-c file] [-r file] [-s n] [-v]

# DESCRIPTION
This program is aimed at reading a record-based file and converting it to
a human-readable format. It reads its settings from the rbf.yaml configuration
file located in the current directory or ~/.rbf directory (linux) or
the %APPDATA%\\local\\rbf directory (Windows).

# OPTIONS

-b
: Benchmark: don't write output file but just read input file.

--br
: Break records: try to break record into individual sub-records for better
text presentation.

-c
: Validate layout structure.

-f file
: Full path and name of a file to filter fields.

--gf records/fields list
: Grep fields: only write selected records/fields.

--gl pattern
: Grep lines: only select lines matching the regex pattern. NB if
"--gf" is also specified, this --gl comes first.

--gr condition
: Grep records: include records matching condition.

-i file
: Full path and name of the file to be read and converted.

-l layout
: Name of the input file layout. This name is found is the
configuration file rbf.xml.

-o format
: Name of the output file format. Possible values are:
html, tag, csv, txt, xlsx, sqlite3, ident. Defaulted to txt
if not specified. ident means the output file format is
the same than the input one.

-O
: Write to standard output only.

-p
: Print out progress.

-r file
: Full path and name of a file to filter records.

-s n
: Only convert the n-first records.

-v
: Verbose: print out options.

-V
: Version.
