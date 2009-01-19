package Perl::Dist::WiX::Base::Entry;

# This class is only here to provide an ISA relationship for 
# validity checking.

use 5.006;
use strict;
use warnings;

use vars qw{$VERSION};
BEGIN {
    $VERSION = '0.11_05';
}

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

1;
