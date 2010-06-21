package Wx::Perl::FormBuilder;

=pod

=head1 NAME

Wx::Perl::FormBuilder - Generate Perl GUI code from wxFormBuilder .fbp files

=head1 SYNOPSIS

  my $generator = Wx::Perl::FormBuilder->new(
      dialog => $fbp_object->dialog('MyDialog')
  );

=head1 DESCRIPTION

TO BE COMPLETED

=cut

use 5.008005;
use strict;
use warnings;
use Moose 1.05;
use FBP   0.02 ();

our $VERSION = '0.01';

has dialog => (
	is       => 'ro',
	isa      => 'FBP::Dialog',
	required => 1,
);

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wx-Perl-FormBuilder>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
