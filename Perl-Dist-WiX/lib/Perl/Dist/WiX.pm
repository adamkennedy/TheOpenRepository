package Perl::Dist::WiX;

=pod

=head1 NAME

Experimental 4th generation Win32 Perl distribution builder

=head1 DESCRIPTION

This package is currently mostly just a placeholder for the eventual
home namespace of a future upgrade to Perl::Dist based on Windows 
Install XML technology, instead of Inno Setup.

=cut

use 5.008;
use strict;
use Params::Util                 ();
use File::ShareDir               ();
use Perl::Dist::WiX::File        ();
use Perl::Dist::WiX::Environment ();
use Perl::Dist::WiX::Component   ();
use Perl::Dist::WiX::Script      ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01_01';
}

sub dist_dir {
	File::ShareDir::dist_dir('Perl-Dist-WiX');
}

1;

=pod

=head1 SUPPORT

No support of any kind is provided for this module

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>, L<Perl::Dist::Inno>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
