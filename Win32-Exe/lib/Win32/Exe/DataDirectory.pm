package Win32::Exe::DataDirectory;

use strict;
use base 'Win32::Exe::Base';
use constant FORMAT => (
    VirtualAddress  => 'V',
    Size	    => 'V',
);

our $VERSION = '0.11_01';
$VERSION =~ s/_//ms;

1;
