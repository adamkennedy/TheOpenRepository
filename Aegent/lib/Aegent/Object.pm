package Aegent::Object;

use 5.008007;
use strict;
use Scalar::Util ();
use Params::Util ();

our $VERSION = '0.01';





######################################################################
# Class Methods

sub meta {
	$Aegent::META{ ref $_[0] or $_[0] }
}

sub MODIFY_CODE_ATTRIBUTES {
	my ($class, $code, $name, @params) = @_;

	# Register an event
	if ( $name eq 'Event' ) {
		# Add to the coderef event register
		$Aegent::EVENT{ Scalar::Util::refaddr $code } = [
			'Aegent::Meta::Event',
		];
		return ();
	}

	# Register a timeout
	if ( $name =~ /^Timeout\b/ ) {
		unless ( $name =~ /^Timeout\((.+)\)$/ ) {
			Carp::croak("Missing or invalid timeout");
		}
		my $delay = $1;
		unless ( Params::Util::_POSINT($delay) ) {
			Carp::croak("Missing or invalid timeout");
		}
		$POE::Declare::EVENT{Scalar::Util::refaddr($code)} = [
			'POE::Declare::Meta::Timeout',
			delay => $delay,
		];
		return ();
	}

	# Unknown method type
	Carp::croak("Unknown or unsupported attribute $name");
}

}





######################################################################
# Constructor

sub new {
	my $class = shift;
	my $meta  = $class->meta;
	my $self  = bless { }, $class;
	my %param = @_;

	# Check the Alias
	if ( exists $param{Alias} ) {
		Params::Util::_STRING($param{Alias}) or
		Carp::croak("Did not provide a valid Alias string param");
		$self->{Alias} = delete $param{Alias};
	} else {
		$self->{Alias} = $meta->alias;
	}

	# Stuff goes here
	die "CODE INCOMPLETE";

	# Check for unsupported params
	if ( %param ) {
		my $names = join ', ', sort keys %param;
		die("Unknown or unsupported $class param(s) $names");
	}

	return $self;
}

1;
