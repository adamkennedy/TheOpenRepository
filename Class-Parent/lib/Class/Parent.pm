package Class::Parent;

=pod

=head1 NAME

Class::Parent - Provides weakened inside-out references to parent objects

=head1 DESCRIPTION

TO BE COMPLETED

=head1 METHODS

=cut

use 5.006;
use strict;
use Scalar::Util ();

use vars qw{$VERSION %PARENT};
BEGIN {
	$VERSION = '0.01';
	%PARENT  = ();
}

sub parent {
	$PARENT{Scalar::Util::refaddr($_[0])};
}

sub DESTROY {
	delete $PARENT{Scalar::Util::refaddr($_[0])};
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Tiny>

For other issues, or commercial support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
