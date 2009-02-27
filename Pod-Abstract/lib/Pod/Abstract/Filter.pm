package Pod::Abstract::Filter;
use strict;
use warnings;

use Pod::Abstract;
use UNIVERSAL qw(isa);

=head1 METHODS

=head2 new

Create a new filter with the specified arguments.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    return bless { %args }, $class;
}

=head2 param

Get the named param. Read only.

=cut

sub param {
    my $self = shift;
    my $param_name = shift;
    return $self->{$param_name};
}

=head2 filter

Stub method. Does nothing, just returns the original tree.

=cut

sub filter {
    my $self = shift;
    my $pa = shift;
    
    return $pa;
}

=head2 run

Run the filter. If $arg is a string, it will be parsed
first. Otherwise, the Abstract tree will be used. Returns either a
string or an abstract tree (which may be the original tree, modified).

=cut

sub run {
    my $self = shift;
    my $arg = shift;
    
    if( isa($arg, 'Pod::Abstract::Node') ) {
        return $self->filter($arg);
    } else {
        my $pa = Pod::Abstract->load_string($arg);
        return $self->filter($pa);
    }
}

1;
