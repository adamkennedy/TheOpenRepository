package YAML::Tiny::Stream;

=pod

=head2 NAME

YAML::Tiny::Stream - Document psuedo-streaming for YAML::Tiny

=head2 DESCRIPTION

To keep the design small and contained, L<YAML::Tiny> intentionally discards
support for streamed parsing of YAML documents.

In situations where a file contains a very large number of very small YAML
documents, B<YAML::Tiny::Stream> provides a limited implementation of streaming
that scans for YAML's --- document separators and parses them one entire
document at a time.

Please note this approach does come with caveats, as any situation in which a
triple dash occurs legitimately at the beginning of a line (such as in a quote)
may be accidently detected as a new document by mistake.

If you really do need a "proper" streaming parser, then you should see L<YAML>
or one of the other full blown YAML implementations.

=cut

use 5.006;
use strict;
use YAML::Tiny ();

our $VERSION = '0.01';

1;

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<YAML>, L<YAML::Syck>, L<Config::Tiny>, L<CSS::Tiny>,
L<http://use.perl.org/~Alias/journal/29427>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
