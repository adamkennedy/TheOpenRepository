package Aspect::Hook;

use strict;
use warnings;

our $VERSION = '0.91';

1;

__END__

=pod

=head1 NAME

Aspect::Hook - Holding area for internal generated code

=head1 DESCRIPTION

During the weaving process L<Aspect> can do a large amount of code generation
and it is important that none of this accidentally pollutes the target packages.

To prevent this, all of this generated code is produced in a dedicated and
isolated namespace.

B<Aspect::Hook> is the namespace in which this happens. Beyond this purpose,
this class services no other purpose.

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
