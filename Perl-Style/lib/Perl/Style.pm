package Perl::Style;

=pod

=head1 NAME

Perl::Style - Modify Perl source in ways that go beyond just tidying

=head1 DESCRIPTION

L<Perl::Tidy> has long provided the standard method for "cleaning up" source
code to make it more beautiful and readable. However, it is necesarily limited
to moving whitespace around. It does not get involved with more concrete
changes to your code.

It also predates L<PPI>. While there has long been a goal to rewrite a new
tidy implementation in L<PPI> the amount of work involved is enormous for no
particularly clear benefit.

Instead of providing an alternative to L<Perl::Tidy>, B<Perl::Style> goes
beyond the set of functionality provided by L<Perl::Tidy> into new territory,
manipulating the B<non> whitespace parts of a document while leaving the
functionality the same (although the changes may actually change the op-tree
of the compiled program at times).

B<Perl::Style> is implemented as a collection of L<PPI::Transform> classes,
with each class representing a preference for (or against) some particular
style of Perl programming in some area.

Configuring B<Perl::Style> involves selecting a subset of style transforms,
indicating preferences for that style transform, and then applying the
collected set of transforms to one or more Perl documents.

Additional global options allow for checks to guard against potential
damage to the file, such as functional signature checks and compilation checks.

In this initial implementation, there is no convenient user interface around
the functionality provided within, and you will need to write your own
custom script to instantiate and execute the style process.

=head1 METHODS

=cut

use 5.008;
use strict;
use PPI::Document  ();
use PPI::Transform ();

our $VERSION = '0.01';

=pod

=head2 new

TO BE COMPLETED

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	return $self;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Style>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Tidy>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
