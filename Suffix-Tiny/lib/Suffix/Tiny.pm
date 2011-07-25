package Suffix::Tiny;

use 5.005;
use strict;

our $VERSION = '0.01';

1;

__END__

=pod

=head1 NAME

Suffix::Tiny - The definition of the ::Tiny suffix which modules should meet

=head1 DESCRIPTION

Over the history of CPAN, a popular method for naming modules in crowded
namespaces is to apply a suffix to the name of an existing module, or to
the namespace which describes that area of functionality.

For example, modules which wrap a complex module to simplify the API for common
use cases often use the suffix C<::Simple>.

Sometimes these are provided by the author of the main package, such as in the
L<LWP> distribution which ships with L<LWP::Simple>.

Alternatively, they may be created by someone else as a response to the original
as in the case of L<Exporter::Simple>, an alternative to L<Exporter>.

Sometimes these namespaces go through trendy periods, such as ...

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Suffix-Tiny>

For other issues contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Config::Simple>, L<Config::General>, L<ali.as>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
