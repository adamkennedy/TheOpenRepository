package Mirror::Config;

use 5.005;
use base 'YAML::Tiny';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub name {
	$_[0]->{name};
}

1;

__END__

=pod

=head1 NAME

Mirror Configuration Object

=head1 DESCRIPTION

blah

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mirror-Config>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<YAML::Tiny>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
