package Business::AU::Data::Postcode;

use 5.005;
use strict;
use base 'Data::Package::CSV';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub module_file { 'postcode.csv' }

sub csv_options { fields => 'auto' }

1;

__END__

=pod

=head1 NAME

Business::AU::Data::Postcode - Freely available Australian Postcode data

=head1 DESCRIPTION

This package provides a data product consisting of a set of Australian
postal codes, along with a GPS location representing the centre of the
postcode area.

The distribution that contains this package intentionally focuses on only
providing the data set, so that it can be updated in the future without
requiring an upgrade of any packages providing actual functionality.

=head2 Implementation

B<Business::AU::Data::Postcode> is implemented as a L<Data::Package> class,
using L<Data::Package::CSV> for the implementation, the actual locations
are returned as L<GPS::Point> objects.

=head1 METHODS

B<Business::AU::Data::Postcode> is a L<Data::Package> class that provides
data as a L<Parse::CSV> object, implemented using L<Data::Package::CSV>.

See the the documentation of those three modules for more details.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-AU-Data-Postcode>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
