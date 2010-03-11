package Win32::Exe::DebugDirectory;

use strict;
use base 'Win32::Exe::Base';
use constant FORMAT => (
    Flags	    => 'V',
    TimeStamp	    => 'V',
    VersionMajor    => 'v',
    VersionMinor    => 'v',
    Type	    => 'V',
    Size	    => 'V',
    VirtualAddress  => 'V',
    Offset	    => 'V',
);

our $VERSION = '0.11_01';
$VERSION =~ s/_//ms;

1;
