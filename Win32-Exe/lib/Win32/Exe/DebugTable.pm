package Win32::Exe::DebugTable;

use strict;
use base 'Win32::Exe::Base';
use constant FORMAT => (
    'DebugDirectory'	=> [ 'a28', '*', 1 ],
);

our $VERSION = '0.11_01';
$VERSION =~ s/_//ms;

1;
