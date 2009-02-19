package Pod::Abstract::Node;
use strict;
use warnings;

use Pod::Abstract::Tree;
use Pod::Abstract::Serial;

=pod

=head1 SYNOPSIS

 $node->nest( @list );          # Nests list as children of $node. If they
                                # exist in a tree they will be detached.
 $node->hoist;                  # Append all children of $node after $node.
 $node->detach;                 # Detaches intact subtree from parent
 $node->select( $path_exp );    # Selects the path expression under $node
 $node->select_into( $target, $path_exp );
                                # Selects into the children of the target node.
 
 $node->insert_before($target); # Inserts $node in $target's tree before $target
 $node->insert_after($target);
 
 $node->push($target);          # Appends $target at the end of this node
 $node->unshift($target);       # Prepends $target at the start of this node
 
 $node->path();                 # List of nodes leading to this one
 $node->children();             # All direct child nodes of this one
 
 $node->duplicate();            # Duplicate node and children in a new tree.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $type = $args{type};
    my $body = $args{body};
    delete $args{type};
    delete $args{body};
    
    my $self = bless {
        tree => Pod::Abstract::Tree->new(),
        serial => Pod::Abstract::Serial->next,
        parent => undef,
        type => $type,
        body => $body,
        params => { %args },
    }, $class;
    
    return $self;
}

sub text_ptree {
    my $self = shift;
    my $indent = shift || 0;
    my $width = 76 - $indent;
    
    my $type = $self->type;
    my $body = $self->body;
    $body =~ s/[\n\t]//g if $body;
    
    my $r = ' ' x $indent;
    if($body) {
        $r .= substr("[$type] $body",0,$width);
    } else {
        $r .= "[$type]";
    }
    $r .= "\n";
    my @children = $self->children;
    foreach my $c (@children) {
        $r .= $c->text_ptree($indent + 2);
    }
    return $r;
}

sub type {
    my $self = shift;
    return $self->{type};
}

sub body {
    my $self = shift;
    return $self->{body};
}

sub duplicate {
    my $self = shift;
    my $class = ref $self;
 
    # Implement the new() call with all the data needed.
    my $dup = new $class;
    
    my @children = $self->children;
    my @dup_children = map { $_->duplicate } @children;
    $dup->nest(@dup_children);
}

sub insert_before {
    my $self = shift;
    my $target = shift;
    
    my $target_tree = $target->parent->tree;
    if($target_tree->insert_before($target, $self)) {
        $self->parent($target_tree);
    } else {
        die "Could not insert before [$target]";
    }
}

sub insert_after {
    my $self = shift;
    my $target = shift;
    
    my $target_tree = $target->parent->tree;
    if($target_tree->insert_after($target, $self)) {
        $self->parent($target_tree);
    } else {
        die "Could not insert before [$target]";
    }
}

sub hoist {
    my $self = shift;
    
    my $n = $self;
    foreach my $target(@_) {
        $target->insert_after($n);
        $n = $target;
    }
    
    return @_;
}

sub push {
    my $self = shift;
    my $target = shift;
    
    my $target_tree = $self->tree;
    if($target_tree->push($target)) {
        $target->parent($target_tree);
    } else {
        die "Could not push [$target]";
    }
}

sub nest {
    my $self = shift;
    
    foreach my $target (@_) {
        $self->push($target);
    }
    
    return @_;
}

sub tree {
    my $self = shift;
    return $self->{tree};
}

sub unshift {
    my $self = shift;
    my $target = shift;
    
    my $target_tree = $self->tree;
    if($target_tree->unshift($target)) {
        $target->parent($target_tree);
    } else {
        die "Could not unshift [$target]";
    }
}

sub serial {
    my $self = shift;
    return $self->{serial};
}

sub attached {
    my $self = shift;
    return defined $self->parent;
}

sub detach {
    my $self = shift;
    
    if($self->parent) {
        $self->parent->tree->detach($self);
        return 1;
    } else {
        return 0;
    }
}

sub parent {
    my $self = shift;
    
    if(@_) {
        my $new_parent = shift;
        if( defined $self->{parent} && 
            $self->parent->tree->detach($self) ) {
            warn "Implicit detach when reparenting";
        }
        $self->{parent} = $new_parent;
    }
    
    return $self->{parent};
}

sub children {
    my $self = shift;
    return $self->tree->children();
}

1;
