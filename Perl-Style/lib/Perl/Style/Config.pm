package Perl::Style::Config;

use 5.008;
use strict;
use warnings;
use YAML::Tiny   ();
use Params::Util ();

our $VERSION = '0.01';





######################################################################
# Constructors

sub new {
	my $class = shift;
	my $self  = bless [ ], $class;

	# Handle the configurations
	if ( Params::Util::_HASH($_[0]) ) {
		my $hash = shift;
		foreach ( sort keys %$hash ) {
			push @$self, [ $_ => $hash->{$_} ];
		}

	} elsif ( Params::Util::_ARRAY($_[0]) ) {
		my $array = shift;
		push @$self, @$array;

	} else {
		die "Missing or invalid config constructor param";
	}

	return $self;
}

sub load {
	my $class = shift;
	my $file  = shift;
	unless ( defined $file and -f $file and -r $file ) {
		die "Missing or invalid config file";
	}

	# Load the file
	my $yaml = YAML::Tiny::LoadFile($file);
	unless ( $yaml ) {
		die "Failed to load config file '$file'";
	}

	# Hand off to the ordinary constructor
	$class->new($yaml);
}

1;
