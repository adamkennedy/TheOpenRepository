#! perl

# Note: DO NOT run this in a previously installed (with the .msi) Strawberry installation.
# Either run this from the .zip, or pack it with PAR::Packer.
# The requirement for 5.012 is really so that Strawberry has relocatability.
# This script can TEST any recent version of Strawberry.

use Perl::Dist::Strawberry::QA;

test;

__END__

=pod

=head1 SYNOPSIS

This script is probably best run like so: (although it can be run independently of L<prove|prove>)

    prove -v strawberry-qa.pl :: --basename strawberry-perl-professional-5.10.0.3-alpha-2

=cut
