package PITA::Report::Test;

=pod

=head1 NAME

PITA::Report::Test - The result of an single executed test script

=head1 DESCRIPTION

The C<PITA::Report::Test> class provides data objects that represent the
output from a single test script.

=head1 METHODS

=cut

use strict;
use Carp         ();
use Params::Util '_SCALAR0';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.04';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

The C<new> constructor is used to create a new test result.

TO BE COMPLETED

Returns a C<PITA::Report::Text> object, or dies on error.

=cut

sub new {
	my $class = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Check the object
	$self->_init;

	$self;
}

sub _init {
	my $self = shift;

	# Check the actual command string
	if ( exists $self->{name} ) {
		my $name = $self->{name};
		unless ( 
			defined $name and ! ref $name
			and
			length $name
		) {
			Carp::croak('Invalid or missing cmd');
		}
	}

	# Check the mime-type
	$self->{language} ||= 'text/x-tap';
	my $language = $self->{language};
	unless (
		defined $language and ! ref $language
		and
		length $language
	) {
		Carp::croak('Invalid or missing language mime-type');
	}

	# Check the STDOUT
	unless ( _SCALAR0($self->{stdout}) ) {
		Carp::croak('Invalid or missing stdout');
	}

	# Check the STDERR
	if ( exists $self->{stderr} ) {
		unless ( _SCALAR0($self->{stderr}) ) {
			Carp::croak('Invalid or missing stderr');
		}
	}

	# Check the optional exit code
	if ( exists $self->{exitcode} ) {
		my $exitcode = $self->{exitcode};
		unless (
			defined $exitcode and ! ref $exitcode
			and
			length $exitcode
		) {
			Carp::croak('Invalid exit code');
		}
	}

	$self;
}

=pod

=head2 name

The C<name> accessor returns the name of the test, if it has one.

Returns a not-null string, or C<undef> if the test is unnamed.

=cut

sub name {
	$_[0]->{name};
}

=pod

=head2 language

The C<language> accessor returns the mime-type of the test output.

This defaults to "text/x-tap" unless otherwise specified.

=cut

sub language {
	$_[0]->{language};
}

=pod

=head2 stdout

The C<stdout> accessor returns the output of the test as a
C<SCALAR> reference.

=cut

sub stdout {
	$_[0]->{stdout};
}

=pod

=head2 stderr

The C<stderr> accessor returns the error output of the command
as a C<SCALAR> reference, or C<undef> if the test was run via a
communications mechanism that does not support error output.

=cut

sub stderr {
	$_[0]->{stderr};
}

=pod

=head2 exitcode

The C<exitcode> accessor returns the process exit code of the test,
if run across a communications mechanism that supports the concept
of an exit code.

Returns a not-null string (generally an integer), or C<undef> if the
test did not return an exit code.

=cut

sub exitcode {
	$_[0]->{exitcode};
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
