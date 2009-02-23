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

#<<<
use 5.006;
use strict;
use warnings;
use Object::InsideOut qw( Perl::Dist::WiX::Misc :Public Storable );
use vars              qw( $VERSION                               );
use version; $VERSION = qv('0.13_04');
#>>>

1;
