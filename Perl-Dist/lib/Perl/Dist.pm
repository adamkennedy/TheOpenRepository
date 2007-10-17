package Perl::Dist;

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.06';
}

1;

__END__

=pod

=head1 NAME

Perl::Dist - Perl Distribution Creation Toolkit

=head1 DESCRIPTION

The Perl::Dist namespace encompasses creation of pre-packaged, binary
distributions of Perl, such as executable installers for Win32.  While initial
efforts are targeted at Win32, there is hope that this may become a more
general support tool for Perl application deployment.

Packages in this namespace include both "builders" and "distributions".
Builder packages automate the generation of distributions.  Distribution
packages contain configuration files for a particular builder, extra files
to be bundled with the pre-packaged binary, and documentation.
Distribution namespaces are also recommended to consolidate bug reporting
using http://rt.cpan.org/.

I<Distribution packages should not contain the pre-packaged install files
themselves.>

B<Please note that this module is currently considered experimental, and
not really suitable for general use>.

=head2 BUILDERS

There is currently only the default builder:

=over

=item *

L<Perl::Dist::Builder> -- an alpha version of a distribution builder

=back

=head2 DISTRIBUTIONS

Currently available distributions include:

=over

=item *

L<Perl::Dist::Vanilla> -- an experimental "core Perl" distribution intended
for distribution developers

=item *

L<Perl::Dist::Strawberry> -- a practical Win32 Perl release for
experienced Perl developers to experiment and test the installation of
various CPAN modules under Win32 conditions

=back

=head1 ROADMAP

Everything is currently alpha, at best.  These packages have been released
to enable community support in ongoing development.

Some specific items for development include:

=over

=item *

Bug-squashing Win32 compatibility problems in popular modules

=item *

Refactoring the initial builder for greater modularity and control of the
build process

=item *

Support for Win32 *.msi installation files instead of standalone *.exe
installers

=item *

Better uninstall support and upgradability

=back

=head1 SEE ALSO

=over

=item *

L<http://win32.perl.org/>

=item *

L<http://vanillaperl.com>

=item *

L<irc://irc.perl.org/#win32>

=back

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

David A. Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

Cyopright 2007 Adam Kennedy

Copyright 2006 David A. Golden

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
