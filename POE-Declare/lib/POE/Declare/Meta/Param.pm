package POE::Declare::Meta::Param;

=pod

=head1 NAME

POE::Declare::Meta::Param - A named attribute passed to the constructor
as a parameter.

=head1 DESCRIPTION

B<POE::Declare::Meta::Param> is a sub-class of
L<POE::Declare::Meta::Attribute>. It defines an attribute for which the
initial value will be passed as a named parameter to the constructor.

After the object has been created, it will still only be read-only.

=cut

use 5.008007;
use strict;
use warnings;
use POE::Declare::Meta::Attribute ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.23_01';
	@ISA     = 'POE::Declare::Meta::Attribute';
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<POE::Declare>

=head1 COPYRIGHT

Copyright 2006 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
