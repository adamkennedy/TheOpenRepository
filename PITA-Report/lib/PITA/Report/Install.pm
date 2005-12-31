package PITA::Report::Install;

=pod

=head1 NAME

PITA::Report::Install - A PITA report on a single distribution install

=head1 DESCRIPTION

C<PITA::Report::Install> is a data object that contains the complete
set of information on a single test/install run for a distribution on a
single host of an arbitrary platform.

=cut

use strict;
use Carp ();
use Params::Util '_INSTANCE',
                 '_SET0';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.04';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  # Create a new Install object
  my $install = PITA::Report::Install->new(
      request  => $request
      platform => $platform,
      analysis => $analysis,
      );

The C<new> constructor is used to create a new installation report, a
collection of which are serialized to the L<PITA::Report> XML file.

Returns a new C<PITA::Report::Install> object, or dies on error.

=cut

sub new {
	my $class  = shift;

	# Create the object
	my $self = bless { @_ }, $class;

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

	# We must have a testing request
	unless ( _INSTANCE($self->{request}, 'PITA::Report::Request') ) {
		Carp::croak('Invalid or missing request');
	}

	# Zero or more commands
	$self->{commands} ||= [];
	unless ( _SET0($self->{commands}, 'PITA::Report::Command') ) {
		Carp::croak('Invalid or incorrect commands');
	}

	# Zero or more tests
	$self->{tests} ||= [];
	unless ( _SET0($self->{tests}, 'PITA::Report::Test') ) {
		Carp::croak('Invalid or incorrect tests');
	}

	# Analysis object is optional
	if ( exists $self->{analysis} ) {
		unless ( _INSTANCE($self->{analysis}, 'PITA::Report::Analysis') ) {
			Carp::croak('Invalid analysis object');
		}
	}

	$self;
}





#####################################################################
# Main Methods

=pod

=head2 request

The C<request> accessor returns testing request information.

Returns a L<PITA::Report::Distribution> object.

=cut

sub request {
	$_[0]->{request};
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

=head2 add_command

  $install->add_command( $command );

The C<add_command> method adds a L<PITA::Report::Command> object to the
list of commands in the install object.

Returns true, or dies is you do not pass a L<PITA::Report::Command> object.

=cut

sub add_command {
	my $self    = shift;
	my $command = _INSTANCE(shift, 'PITA::Report::Command')
		or Carp::croak("Did not provide a PITA::Report::Command to add_command");
	push @{ $self->{commands} }, $command;
	1;
}

=pod

=head2 commands

The C<commands> accessor returns the commands executed during the testing.

Returns a list of zero or more L<PITA::Report::Command> objects.

=cut

sub commands {
	@{ $_[0]->{commands} };
}

=pod

=head2 add_test

  $install->add_test( $test );

The C<add_test> method adds a L<PITA::Report::Test> object to the
list of test results in the install object.

Returns true, or dies is you do not pass a L<PITA::Report::Test> object.

=cut

sub add_test {
	my $self = shift;
	my $test = _INSTANCE(shift, 'PITA::Report::Test')
		or Carp::croak("Did not provide a PITA::Report::Test to add_test");
	push @{ $self->{tests} }, $test;
	1;
}

=pod

=head2 tests

The C<tests> accessor returns the results of the individual tests run during the testing.

Returns a list of zero or more L<PITA::Report::Test> objects.

=cut

sub tests {
	@{ $_[0]->{tests} };
}

=pod

=head2 analysis

The C<analysis> accessor returns the analysis object for the test run.

Returns a L<PITA::Report::Analysis> object, or C<undef> if no analysis
performed during the testing.

=cut

sub analysis {
	$_[0]->{analysis};
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
