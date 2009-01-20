package Perl::Dist::WiX::Base::Entry;

# This class is only here to provide an ISA relationship for 
# validity checking.

=pod

=head1 NAME

Perl::Dist::WiX::Base::Fragment - Base class for entry tags.

=head1 DESCRIPTION

This is a base class for classes that create entry tags (tags 
contained in <Component> tags, and is here to provide an ISA
relationship for validity checking. It is meant to be subclassed, 
as opposed to creating objects of this class directly.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

use vars qw{$VERSION};
BEGIN {
    $VERSION = '0.11_05';
}

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

1;

=head1 SUPPORT

No support of any kind is provided for this module

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist|Perl::Dist>, L<Perl::Dist::WiX|Perl::Dist::WiX>

=head1 COPYRIGHT

Copyright 2009 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
