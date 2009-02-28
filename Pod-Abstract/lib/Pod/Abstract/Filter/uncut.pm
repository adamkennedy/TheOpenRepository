package Pod::Abstract::Filter::uncut;
use strict;
use warnings;

use base qw(Pod::Abstract::Filter);
use Pod::Abstract::BuildNode qw(node);

sub filter {
    my $self = shift;
    my $pa = shift;
    
    my @cuts = $pa->select('//#cut[! << #cut]'); # First cut in each run
    
    foreach my $cut (@cuts) {
        next unless $cut->body =~ m/^=cut/;
        my $n = $cut->next;
        while( $n && $n->type eq '#cut' ) {
            $cut->push(node->verbatim($n->body));
            $n->detach;
            $n = $cut->next;
        }
        $cut->coalesce_body(':verbatim');
        $cut->hoist;
        $cut->detach;
    }
    
    return $pa;
}

1;