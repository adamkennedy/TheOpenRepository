package Pod::Abstract::Filter::html;

use strict;
use warnings;

use base qw(Pod::Abstract::Filter);

our $VERSION = '0.21';

sub filter {
    my $self = shift;
    my $pa = shift;
    
    return 
        "<html><body>" . 
            $self->html_nodes($pa->children) . 
        "</body></html>";
}

sub html_nodes {
    my $self = shift;
    my @nodes = @_;
    
    foreach
}