package Perl::Dist::WiX::EnvironmentEntry;

####################################################################
# Perl::Dist::WiX::EnvironmentEntry - Object that represents an <Environment> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# $Rev$ $Date$ $Author$
# $URL$

use 5.006;
use strict;
use warnings;
use Carp                          qw( croak               );
use Params::Util                  qw( _IDENTIFIER _STRING );
use Data::UUID                    qw( NameSpace_DNS       );
require Perl::Dist::WiX::Base::Entry;

use vars qw( $VERSION @ISA );
BEGIN {
    $VERSION = '0.13_01';
    @ISA = 'Perl::Dist::WiX::Base::Entry';
}

#####################################################################
# Accessors:
#   see new.

use Object::Tiny qw{
    id
    name
    value
    action
    part
    permanent
};

#####################################################################
# Constructors for EnvironmentEntry
#
# Parameters: [pairs]
#   id: The Id attribute of the <Environment> tag being defined.
#   name: The Name attribute of the <Environment> tag being defined.
#   Value: The Value attribute of the <Environment> tag being defined.
#   action: The Action attribute of the <Environment> tag being defined.
#   part: The Part attribute of the <Environment> tag being defined.
#   permanent: The Permanent attribute of the <Environment> tag being defined.
# Note: see http://wix.sourceforge.net/manual-wix3/wix_xsd_environment.htm for valid values.

sub new {
    my $self = shift->SUPER::new(@_);

    # Check params
    unless ( _STRING($self->id) ) {
        croak("Missing or invalid id param");
    }
    unless ( _STRING($self->{name}) ) {
        croak("Missing or invalid name param");
    }
    unless ( _STRING($self->{value}) ) {
        croak("Missing or invalid value param");
    }
    unless ( _STRING($self->{action}) ) {
        $self->{action} = 'set';
    }
    unless ( _STRING($self->{part}) ) {
        $self->{part} = 'all';
    }
    unless ( _STRING($self->{permanent}) ) {
        $self->{permanent} = 'no';
    }

    return $self;
}


#####################################################################
# Main Methods

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing <Environment> tag defined by this object.

sub as_string {
    my $self = shift;

    # Print tag.
    my $answer = <<END_OF_XML;
   <Environment Id='E_$self->{id}' Name='$self->{name}' Value='$self->{value}' 
      System='yes' Permanent='$self->{permanent}' Action='$self->{action}' Part='$self->{part}' />
END_OF_XML
    
    return $answer;
}

1;
