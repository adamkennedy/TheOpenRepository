package Pod::Abstract::Tree;
use strict;

=head1 NAME

Pod::Abstract::Tree - Manage a level of Pod document tree Nodes.

=head1 DESCRIPTION

Pod::Abstract::Tree keeps track of a set of Pod::Abstract::Node
elements, and allows manipulation of that list of elements. Elements
are stored in an ordered set - a single node can appear once only in a
single document tree, so inserting a node at a point will also remove
it from it's previous location.

=cut

sub new {
    my $class = shift;

    return bless {
        id_map => { },
        nodes => [ ],
    }, $class;
}

sub detach {
    my $self = shift;
    my $node = shift;
    my $id_map = $self->{id_map};
    
    my $idx = $id_map->{$node->serial};
    return 0 unless defined $idx;
    
    # Node is defined, remove it:
    splice @{$self->{nodes}},$idx,1;
    delete $id_map->{$node->serial};
    
    #  Move all following nodes back by 1
    my $length = scalar @{$self->{nodes}};
    for(my $i = $idx; $i < $length; $i ++) {
        my $s = $self->{nodes}[$i];
        $id_map->{$s} --;
    }
    
    # Node now has no parent.
    $node->parent(undef);
    return $node;
}

=head1 push

Add an element to the end of the node list.

=cut

sub push {
    my $self = shift;
    my $node = shift;
    
    if($node->attached) {
        $node->detach;
        warn "Implicit detach of node on push";
    }
    
    my $s = $node->serial;
    push @{$self->{nodes}}, $node;
    $self->{id_map}{$s} = $#{$self->{nodes}};
    return 1;
}

=head1 pop

=cut

sub pop {
    my $self = shift;
    
    my $node = pop @{$self->{nodes}};
    my $s = $node->serial;
    delete $self->{id_map}{$s};
    $node->parent(undef);

    return $node;
}

=head1 insert_before

=cut

sub insert_before {
    my $self = shift;
    my $target = shift;
    my $node = shift;
    
    my $idx = $self->{id_map}{$target->serial};
    return 0 unless defined $idx;
    
    splice(@{$self->{nodes}}, $idx, 0, $node);
    $self->{id_map}{$node->serial} = $idx;

    # Push all following nodes forwards by 1.
    my $length = scalar @{$self->{nodes}};
    for( my $i = $idx + 1; $i < $length; $i ++) {
        my $s = $self->{nodes}[$i]->serial;
        $self->{id_map}{$s} ++;
    }
    return 1;
}

=head1 insert_after

=cut
sub insert_after {
    my $self = shift;
    my $target = shift;
    my $node = shift;
    
    my $idx = $self->{id_map}{$target->serial};
    die $target->serial, " not in index ", join(", ", keys %{$self->{id_map}})
        unless defined $idx;
    my $last_idx = $#{$self->{nodes}};
    if($idx == $last_idx) {
        return $self->push($node);
    } else {
        my $before_target = $self->{nodes}[$idx + 1];
        return $self->insert_before($before_target, $node);
    }
}

=head1 unshift

Unshift takes linear time - it has to relocate every other element in
id_map so that they stay in line.

=cut

sub unshift {
    my $self = shift;
    my $node = shift;

    if($node->attached) {
        $node->detach;
        warn "Implicit detach of node on unshift";
    }
    
    my $s = $node->serial;
    foreach my $k (keys %{$self->{id_map}}) {
        $self->{id_map}{$k} ++;
    }
    unshift @{$self->{nodes}}, $node;
    $self->{id_map}{$s} = 0;
}

sub children {
    my $self = shift;
    return @{$self->{nodes}};
}

1;
