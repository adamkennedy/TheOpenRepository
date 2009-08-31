package Perl::Dist::WiX::Exceptions;

####################################################################
# Perl::Dist::WiX::Exceptions - Exception classes for Perl::Dist::WiX.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See WiX.pm for details.
#
# NOTE: This is a base class with miscellaneous routines.  It is
# meant to be subclassed, as opposed to creating objects of this
# class directly.

use     5.008001;
use     strict;
use     warnings;

our $VERSION = '1.090';
$VERSION = eval { return $VERSION };


#####################################################################
# Error Handling

use Exception::Class (
	'PDWiX'            => { 'description' => 'Perl::Dist::WiX error', },
	'PDWiX::Parameter' => {
		'description' =>
		  'Perl::Dist::WiX error: Parameter missing or invalid',
		'isa'    => 'PDWiX',
		'fields' => [ 'parameter', 'where' ],
	},
	'PDWiX::Caught' => {
		'description' =>
		  'Error caught by Perl::Dist::WiX from other module',
		'isa'    => 'PDWiX',
		'fields' => [ 'message', 'info' ],
	},
	'PDWiX::Unimplemented' => { 
		'description' => 'Perl::Dist::WiX error: Routine unimplemented', 
		'isa'    => 'PDWiX',
	},
);

sub PDWiX::full_message { ## no critic 'Capitalization'
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->message() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";
	my $misc       = WiX3::Traceable->new();
	my $tracelevel = $misc->get_tracelevel();

	# Add trace to it if tracelevel high enough.
	if ( $tracelevel > 1 ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	return $string;
} ## end sub PDWiX::full_message

sub PDWiX::Parameter::full_message { ## no critic 'Capitalization'
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->parameter()
	  . ' in Perl::Dist::WiX'
	  . $self->where() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";
	my $misc       = WiX3::Traceable->new();
	my $tracelevel = $misc->get_tracelevel();

	# Add trace to it. (We automatically dump trace for parameter errors.)
	$string .= "\n" . $self->trace() . "\n";

	return $string;
} ## end sub PDWiX::Parameter::full_message

sub PDWiX::Caught::full_message { ## no critic 'Capitalization'
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->message() . "\n"
	  . $self->info() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";
	my $misc       = WiX3::Traceable->new();
	my $tracelevel = $misc->get_tracelevel();

	# Add trace to it if tracelevel high enough.
	if ( $tracelevel > 1 ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	return $string;
} ## end sub PDWiX::Caught::full_message


1;
