package PITA::Report::Platform;

=pod

=head1 NAME

PITA::Report::Platform - Data object representing a platform configuration

=head1 SYNOPSIS

  # Create a platform configuration
  my $platform = PITA::Report::Platform->new(
  	bin    => '/usr/bin/perl',
  	env    => \%ENV,
  	config => \%Config::Config,
  	);
  
  # Get the current platform configuration
  my $current = PITA::Report::Platform->current;

=head1 DESCRIPTION

C<PITA::Report::Platform> is an object for holding information about
the platform that a package is being tested on

It can be created either as part of the parsing of a L<PITA::Report> XML
file, or if you wish you can create one from the local system configuration.

Primarily it just holds information about the host's environment and the
Perl configuration.

=head1 METHODS

As the functionality for L<PITA::Report> is still in flux, the methods
will be documented once we stop changing them daily :)

=cut

use strict;
use Carp         ();
use Params::Util '_HASH';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class  = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Check the object
	$self->_init;

	$self;
}

sub current {
	my $class = shift;

	# Source the information
	my $bin = $^X;
	require Config;
	
	# Hand off to the main constructor
	$class->new(
		bin    => $bin,
		env    => { %ENV },            # Take a copy
		config => { %Config::Config }, # Take a copy
		);
}

# Format-check the parameters
sub _init {
	my $self = shift;

	# Check the binary we used
	my $bin = $self->{bin};
	unless (
		defined $bin and ! ref $bin
		and
		length $bin
	) {
		Carp::croak('Invalid binary path');
	}

	# Check we have an environment
	unless ( _HASH($self->{env}) ) {
		Carp::croak('Missing or empty environment');
	}

	# Check we have a config
	unless ( _HASH($self->{config}) ) {
		Carp::croak('Missing or empty config');
	}

	$self;
}

sub bin { $_[0]->{bin} }

sub env { $_[0]->{env} }

sub config { $_[0]->{config} }

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-Report>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 SEE ALSO

L<PITA::Report>

The Perl Image-based Testing Architecture (L<http://ali.as/pita/>)

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
