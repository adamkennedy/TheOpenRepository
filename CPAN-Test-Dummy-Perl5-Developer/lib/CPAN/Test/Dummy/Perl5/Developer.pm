package CPAN::Test::Dummy::Perl5::Developer;

use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01_01';
}

sub dummy { 'Mr Nobody' }

1;

__END__

=pod

=head1 NAME

CPAN::Test::Dummy::Perl5::Developer - CPAN Test Dummy developer sample module

=head1 SYNOPSIS

    use CPAN::Test::Dummy::Perl5::Developer;
    
    my $name = CPAN::Test::Dummy::Perl5::Developer->dummy;

=head1 DESCRIPTION

This module has been created for use in testing suites. It contains
no function of actual use, and only exists to provide certain
guarentees about it's own existance.

This module will never exist in the CPAN index, looks like a developer
release, and will never be deleted.

In the CPAN master repository, or in a full mirror, it will exist forever
as F<ADAMK/CPAN-Test-Dummy-Perl5-Developer-0.01_01.tar.gz>.

=head2 Module Guarantees

1. Contains no functionality, and will never do so.

2. Has no non-core depencies, and will never have any.

3. Exists on CPAN.

4. Does not exist in the CPAN index, and never will.

5. Has a file name with a typical pattern of a develop module.

6. No release will ever be deleted from the CPAN.

=head2 Uses for This Module

This allows several types of testing to be done.

Filename related issues can be tested with a known developer release.

The module name and path can be hard-coded into tests without risking
that file to later dissapear.

Because it should always exist on a full mirror, but never exist on
an index-only mirror (such as those created by L<minicpan>) then if
the mirror is already know to exist, the existance of this module can
be used to differentiate the type of a mirror between full or index-only.

In combination with other CPAN Dummy modules, other types of situations
may also be able to be set up to test behaviour in those situations.

=head1 METHODS

CPAN::Test::Dummy::Perl5::Developer is derived from
PITA::Test::Dummy::Perl5::Make.

=head2 dummy

Returns the dummy's name, in this case 'Mr Nobody'

=head1 AUTHOR

Adam Kennedy C<< <cpan at ali.as> >>

=head1 SUPPORT

No support is available for Mr Nobody.

=head1 SEE ALSO

L<CPAN>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Adam Kennedy, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
