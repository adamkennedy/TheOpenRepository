package CGI::Record;

=pod

=head1 NAME

CGI::Record - Recording and replaying CGI sessions

=head1 SYNOPSIS

  # In your CGI application
  use CGI::Record '/path/to/sqlite.db';

=head1 DESCRIPTION

B<CGI::Record> is a tool for recording (and optionally replaying)
entire sessions of CGI activity methodically correctly.

B<CGI::Record> is the bigger brother of, and a wrapper around,
L<CGI::Capture>.

While L<CGI::Capture> provides just the CGI capturing and apply
mechanism without any additional functionality (in order to keep
dependencies down) B<CGI::Record> adds addition functionality for
capture large amounts of CGI calls in sequence, at the expense of
additional dependency bloat.

=head1 METHODS

=cut

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $recorder = CGI::Record->new(
      file => '/path/to/sqlite.db',
  );

=cut

sub new {
	my $class = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Check params
	

	return $self;
}





#####################################################################
# Main Methods

1;

=pod

=head1 SUPPORT

No support is available for this module

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

