package Template::Preload;
use strict;
use warnings;
use XXX;

use Template::Provider();

sub provider {
    my $class = shift;
    my $provider = Template::Provider->new(@_);
}

1;

=head1 NAME

Template

=cut
