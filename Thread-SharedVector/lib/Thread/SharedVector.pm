package Thread::SharedVector;

use 5.006002;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Thread::SharedVector', $VERSION);

1;

__END__

=head1 NAME

Thread::SharedVector - An experiment in threading blah

=head1 SYNOPSIS

  TODO

=head1 DESCRIPTION

  TODO

=head1 SEE ALSO

  TODO

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
