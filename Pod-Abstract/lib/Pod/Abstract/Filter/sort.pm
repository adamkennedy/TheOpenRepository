package Pod::Abstract::Filter::sort;
use strict;
use warnings;

use Data::Dumper;

use base qw(Pod::Abstract::Filter);

sub filter {
    my $self = shift;
    my $pa = shift;
    
    my $heading = $self->param('heading');
    $heading = 'METHODS' unless defined $heading;
    
    my @targets = $pa->select("//[\@heading =~ {$heading}]");
    foreach my $t (@targets) {
        my @ignore = $t->select("/[!\@heading]");
        my @to_sort = $t->select("/[\@heading]");
        
        $t->clear;
        $t->nest(@ignore);
        $t->nest(
            sort { 
                $a->param('heading')->pod cmp
                $b->param('heading')->pod
            } @to_sort
            );
    }
    return $pa;
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
