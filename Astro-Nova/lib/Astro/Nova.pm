package Astro::Nova;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Astro::Nova', $VERSION);

1;
__END__

=head1 NAME

Astro::Nova - Perl interface to libnova

=head1 SYNOPSIS

  use Astro::Nova;
  blah blah blah

=head1 DESCRIPTION

A libnova wrapper.

TODO

=head2 EXPORT

None by default.

=head1 SEE ALSO

libnova website: L<http://libnova.sourceforge.net/>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
