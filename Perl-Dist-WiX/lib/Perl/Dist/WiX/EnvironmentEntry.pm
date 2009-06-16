package Perl::Dist::WiX::EnvironmentEntry;

####################################################################
# Perl::Dist::WiX::EnvironmentEntry - Object that represents an <Environment> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use 5.008001;
use strict;
use warnings;
use vars              qw( $VERSION                              );
use Object::InsideOut qw( Perl::Dist::WiX::Base::Entry Storable );
use Params::Util      qw( _IDENTIFIER _STRING                   );

use version; $VERSION = version->new('0.184')->numify;
#>>>
#####################################################################
# Accessors:
#   see new.

my @id : Field : Arg(Name => 'id', Required => 1);
my @name : Field : Arg(Name => 'name', Required => 1);
my @value : Field : Arg(Name => 'value', Required => 1);
my @action : Field : Arg(Name => 'action');
my @part : Field : Arg(Name => 'part');
my @permanent : Field : Arg(Name => 'permanent');


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

sub _init : Init {
	my $self      = shift;
	my $object_id = ${$self};

	# Check params
	unless ( _STRING( $id[$object_id] ) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '::EnvironmentEntry->new'
		);
	}
	unless ( _STRING( $name[$object_id] ) ) {
		PDWiX::Parameter->throw(
			parameter => 'name',
			where     => '::EnvironmentEntry->new'
		);
	}
	unless ( _STRING( $value[$object_id] ) ) {
		PDWiX::Parameter->throw(
			parameter => 'value',
			where     => '::EnvironmentEntry->new'
		);
	}

	# TODO: Check for valid enums...
	unless ( _STRING( $action[$object_id] ) ) {
		$action[$object_id] = 'set';
	}
	unless ( _STRING( $part[$object_id] ) ) {
		$part[$object_id] = 'all';
	}
	unless ( _STRING( $permanent[$object_id] ) ) {
		$permanent[$object_id] = 'no';
	}

	return $self;
} ## end sub _init :


#####################################################################
# Main Methods

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing <Environment> tag defined by this object.

sub as_string {
	my $self      = shift;
	my $object_id = ${$self};

	# Print tag.
	my $answer = <<"END_OF_XML";
   <Environment Id='E_$id[$object_id]' Name='$name[$object_id]' Value='$value[$object_id]'
      System='yes' Permanent='$permanent[$object_id]' Action='$action[$object_id]' Part='$part[$object_id]' />
END_OF_XML

	return $answer;
} ## end sub as_string

1;
