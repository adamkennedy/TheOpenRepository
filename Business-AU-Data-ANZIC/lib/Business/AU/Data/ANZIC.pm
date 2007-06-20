package Business::AU::Data::ANZIC;

use 5.005;
use strict;
use base 'Data::Package::CSV';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.00';
}

sub module_file { 'anzic.csv' }

1;

__END__

=pod

=head1 NAME

Business::AU::Data::ANZIC - Australian New Zealand Standard Industrial Classification (ANZSIC) Codes

=head1 SYNOPSIS

  use Business::AU::Data::ANZIC;
  
  my $parser = Business::AU::Data::ANZIC->get('Parse::CSV');

=head1 DESCRIPTION

B<Business::AU::Data::ANZIC> is a module which ties the Australia and
New Zealand Standard Industrial Classification (ANZSIC) Codes to a
cpan namespace.

For applications that need to capture and store information on the
sector of the Australian economy that a business or person operates in,
this module provides data that can be used to specify the industry sector.

The data is provided internally as a CSV heirachal serialization of the
official Australian Bureau of Statistics data cube from product 1292.0.

L<http://www.abs.gov.au/AUSSTATS/abs@.nsf/DetailsPage/1292.02006?OpenDocument>

=head2 Using this module

This module provides the raw data access using the L<Data::Package> API, and
is implemented as a L<Data::Package::CSV> subclass.

The modules will provide the data as either a raw L<IO::File> handle, or
as a L<Parse::CSV> object with numeric columns, from which you can
fetch rows that can be used to compile your task-specific list.

=head1 METHODS

See L<Data::Package> for API details.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-AU-Data-ANZIC>

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
