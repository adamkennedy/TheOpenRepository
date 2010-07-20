package Aegent;

=pod

=head1 NAME

Aegent - Build complex applications from simple AnyEvent parts

=head1 SYNOPSIS

  TO BE COMPLETED

=head1 DESCRIPTION

TO BE COMPLETED

=cut

use 5.008007;
use strict;
use Aegent::Object    ();
use Aegent::Class     ();
use Aegent::Attribute ();

our $VERSION = '0.01';

# Metadata Storage
our %CLASS     = ();
our %ATTRIBUTE = ();
our %EVENT     = ();

1;

__END__

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Aegent>

=begin html

For other issues, or commercial enhancement or support, please contact
<a href="http://ali.as/">Adam Kennedy</a> directly.

=end html

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<AE>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
