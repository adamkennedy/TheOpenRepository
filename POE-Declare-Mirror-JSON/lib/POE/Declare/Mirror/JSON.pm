package POE::Declare::Mirror::JSON;

=pod

=head1 NAME

POE::Declare::Mirror::JSON - Mirror configuration and auto-discovery

=head1 SYNOPSIS

    my $client = POE::Declare::Mirror::JSON->new(
        Timeout     => 10,
        MirrorEvent => \&selected_mirror,
    );
    
    $client->;

=head1 DESCRIPTION

This is a port of L<LWP::Online> to L<POE::Declare>. It behaves similarly to
the original, except that it does not depend on LWP and can execute the HTTP
probes in parallel.

=cut

use 5.008;
use strict;
use URI                        1.56 ();
use File::Spec                 0.80 ();
use Time::HiRes              1.9721 ();
use Time::Local              1.2000 ();
use Params::Util               1.00 ();
use POE::Declare::HTTP::Client 0.04 ();

our $VERSION = '0.01';

use POE::Declare 0.54 {
	Timeout => 'Param',
};

compile;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare-Mirror-JSON>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<LWP::Simple>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
