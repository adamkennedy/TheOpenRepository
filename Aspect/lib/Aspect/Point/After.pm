package Aspect::Point::After;

use strict;
use warnings;
use Aspect::Point ();

our $VERSION = '0.982';
our @ISA     = 'Aspect::Point';

1;

__END__

=pod

=head1 NAME

Aspect::Point - The Join Point context for "after" advice code

=head1 DESCRIPTION

This class implements the methods available for topic object in C<after> advice
implemented via the L<Aspect::Advice::After>.

It supports all methods described in the main L<Aspect::Point> documentation
except for the C<proceed> method (which is exclusive to C<around> advice).

This class is an implementation convenience, and may be refactored away in a
future release of the L<Aspect> distribution.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2011 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
