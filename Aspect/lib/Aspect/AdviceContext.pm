package Aspect::AdviceContext;

use strict;
use warnings;
use Aspect::Point ();

our $VERSION = '0.92';
our @ISA     = 'Aspect::Point';

1;

__END__

=pod

=head1 NAME

Aspect::AdviceContext - The join point context object (DEPRECATED)

=head1 DESCRIPTION

B<This module has been deprecated and is included for back-compatibility.>

See L<Aspect::Point> for the replacement to this module.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2010 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
