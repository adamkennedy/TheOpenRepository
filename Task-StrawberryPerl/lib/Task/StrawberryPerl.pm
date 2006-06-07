package Task::Strawberry;

use 5.008005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

1;

__END__

=pod

=head1 NAME

Task::StrawberryPerl - Specification for modules bundled with Strawberry Perl

=head1 DESCRIPTION

Strawberry Perl is the second in a series of Win32 Perl distributions.

It includes the Perl CORE, plus a defined set of additional modules with
various minimum versions.

This L<Task> module represents the complete dependency specification for
the Strawberry Perl distribution, and lists all dual and non-core modules
that are part of the Strawberry Perl specification.

As well as providing a basis for the build process to install the required
modules, it also means that a distribution such as Vanilla Perl (the
smaller core-only Win32 distribution from the same series) can be upgraded
to something that meets the Strawberry Perl specification, and indeed
response as if it was Strawberry Perl.

=head1 TODO

The current specification is only preliminary and is being uploaded to CPAN
for the purpose for testing the installation of the various modules,
locating bugs, recording the current concensus on what will or will not
be in the distribution "out of the box", and determining the optimum
order of the dependencies (to minimize installation recursion when upgrading
from Vanilla et al).

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Task>, L<http://camelpack.sourceforge.net/>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
