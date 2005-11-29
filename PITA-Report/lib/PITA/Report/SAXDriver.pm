package PITA::Report::SAXDriver;

=pod

=head1 NAME

PITA::Report::SAXDriver - Implements a SAX Driver for PITA::Report objects

=cut

use strict;
use base 'XML::SAX::Base';
use Carp         ();
use Params::Util ':ALL';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}






#####################################################################
# Constructor

sub new {
	my $class  = shift;
	my $parent = _INSTANCE(shift, 'PITA::Report')
		or Carp::croak("Did not provie a PITA::Report param");

	# Create the basic parsing object
	my $self = bless {
		parent => $parent,
		}, $class;

	$self;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-Report>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
