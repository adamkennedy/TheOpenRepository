package Math::ThinPlateSpline;

use 5.008;
use strict;
use warnings;
use Carp 'croak';

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Math::ThinPlateSpline', $VERSION);


1;
__END__

=head1 NAME

Math::ThinPlateSpline - Calculate and evaluate thin plate splines

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The Math::ThinPlateSpline module is

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

The included tpsfit library is

Copyright (C) 2001-2003,2005 Jarno Elonen

Copyright (C) 2010 by Steffen Mueller

This library is Free Software / Open Source with a very permissive
license:

Permission to use, copy, modify, distribute and sell this software
and its documentation for any purpose is hereby granted without fee,
provided that the above copyright notice appear in all copies and
that both that copyright notice and this permission notice appear
in supporting documentation.  The authors make no representations
about the suitability of this software for any purpose.
It is provided "as is" without express or implied warranty.

=cut
