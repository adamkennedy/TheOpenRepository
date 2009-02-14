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

use 5.006;
use strict;
use warnings;
use vars      qw( $VERSION              );
use base      qw( Perl::Dist::WiX::Misc );
use version;  $VERSION = qv('0.13_02');

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    
    return $self;
}

1;
