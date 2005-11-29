package PITA::Report::Install;

=pod

=head1 NAME

PITA::Report::Install - A PITA report on a single distribution install

=head1 DESCRIPTION

C<PITA::Report::Install> is a data object that contains the complete
information on a single install of a distribution on a single host of
an arbitrary platform.

=cut

use strict;
use Carp         ();
use Params::Util '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01_01';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  # Create a new Install object
  my $install = PITA::Report::Install->new(
      distribution => $distribution,
  
      # Optional (auto-generate if not supplied)
      platform     => $platform,
  
      ### Further params to be added later
      ...
      );

The C<new> constructor is used to create a new installation report, a
collection of which are serialized to the L<PITA::Report> XML file.

Returns a new C<PITA::Report::Install> object, or dies on error.

=cut

sub new {
	my $class  = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# If no platform object was passed to the constructor,
	# use the current platform's information
	unless ( exists $self->{platform} ) {
		$self->{platform} = PITA::Report::Platform->current;
	}

	# Check the object
	$self->_init;

	$self;
}

sub _init {
	my $self = shift;

	# We must have a platform spec
	unless ( _INSTANCE($self->{platform}, 'PITA::Report::Platform') ) {
		Carp::croak('Invalid or missing platform');
	}

	# We must have a distribution spec
	unless ( _INSTANCE($self->{distribution}, 'PITA::Report::Distribution') ) {
		Carp::croak('Invalid or missing distribution');
	}

	1;
}

=pod

=head2 platform

The C<platform> accessor returns the platform specification for the install.

Returns a L<PITA::Report::Platform> object.

=cut

sub platform {
	$_[0]->{platform};
}

=pod

=head2 distribution

The C<distribution> accessor returns information about the
distribution to be installed.

Returns a L<PITA::Report::Distribution> object.

=cut

sub distribution {
	$_[0]->{distribution};
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
