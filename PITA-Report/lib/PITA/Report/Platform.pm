package PITA::Report::Platform;

=pod

=head1 NAME

PITA::Report::Platform - Data object representing a platform configuration

=head1 SYNOPSIS

  # Create a platform configuration
  my $platform = PITA::Report::Platform->new(
  	# Mandatory fields
  	perlv    => join('', `perl -V`),
  	# Optional fields
  	osname   => '...',
  	archname => '...',
  	);
  
  # Get the current platform configuration
  my $current = PITA::Report::Platform->current;

=head1 DESCRIPTION

C<PITA::Report::Platform> is an object for holding information about
the platform that a package is being tested on.distribution to be tested.

It can be created either as part of the parsing of a L<PITA::Report> XML
file, or if you wish you cn create one from the local system configuration.

It holds the contents of the very verbose 'perl -V', plus the name of the
operating system and architecture (for convenience).

=head1 METHODS

=cut

use strict;
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01_01';
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

	# Get the perl -V output
	my $perlpath = $^X;
	my $perlv    = join('', `$^X -V`);
	my $osname   = $perlv =~ /\bosname=(.+?),/ ? $1
		: die "Failed to locate osname in perl -V output";
	my $archname = $perlv =~ /\barchname=(.+?)\s/ ? $1
		: die "Failed to locate archname in perl -V output";

	# Hand off to the main constructor
	$class->new(
		perlpath => $perlpath,
		perlv    => $perlv,
		osname   => $osname,
		archname => $archname,
		);
}

# Format-check the parameters
sub _init {
	my $self = shift;

	# Check the osname
	if ( $self->{osname} ) {
		my $osname = $self->{osname};
		unless (
			defined $osname and ! ref $osname
			and
			length $osname
		) {
			Carp::croak('Invalid osname');
		}	
	} else {
		$self->{osname} = '';
	}

	# Check the archname
	if ( $self->{archname} ) {
		my $archname = $self->{archname};
		unless (
			defined $archname and ! ref $archname
			and
			length $archname
		) {
			Carp::croak('Invalid archname');
		}	
	} else {
		$self->{archname} = '';
	}

	# Check the perlv
	my $perlv = $self->{perlv};
	unless (
		defined $perlv and ! ref $perlv
		and
		$perlv =~ /^Summary of my perl/
		and
		$perlv =~ /\@INC/,
	) {
		Carp::croak('Invalid Perl -V output');
	}

	1;
}

sub perlv {
	$_[0]->{perlv};
}

sub archname {
	$_[0]->{archname};
}

sub osname {
	$_[0]->{osname};
}

sub perlpath {
	$_[0]->{perlpath};
}

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
