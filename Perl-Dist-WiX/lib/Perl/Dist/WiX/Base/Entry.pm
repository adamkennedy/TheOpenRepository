package Perl::Dist::WiX::Base::Entry;

#####################################################################
# Perl::Dist::WiX::Base::Entry - Base class for entries.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# WARNING: Class not meant to be created directly.
# Use as virtual base class and for "isa" tests only.
#
# $Rev$ $Date$ $Author$
# $URL$

use 5.006;
use strict;
use warnings;

use vars qw( $VERSION );
BEGIN {
    $VERSION = '0.11_07';
}

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

1;
