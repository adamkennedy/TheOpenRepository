package Pod::Abstract::Node;
use strict;
use warnings;

use Pod::Abstract::Tree;
use Pod::Abstract::Serial;

=pod

=head1 SYNOPSIS

 $node->nest( @list );          # Nests list as children of $node. If they
                                # exist in a tree they will be detached.
 $node->clear;                  # Remove all children of $node
 $node->hoist;                  # Append all children of $node after $node.
 $node->detach;                 # Detaches intact subtree from parent
 $node->select( $path_exp );    # Selects the path expression under $node
 $node->select_into( $target, $path_exp );
                                # Selects into the children of the
                                # target node.  (copies)
 
 $node->insert_before($target); # Inserts $node in $target's tree before $target
 $node->insert_after($target);
 
 $node->push($target);          # Appends $target at the end of this node
 $node->unshift($target);       # Prepends $target at the start of this node
 
 $node->path();                 # List of nodes leading to this one
 $node->children();             # All direct child nodes of this one
 
 $node->duplicate();            # Duplicate node and children in a new tree.
 
 $node->pod;                    # Convert node back into literal POD
 $node->ptree;                  # Show visual (abbreviated) parse tree

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

sub ptree {
    my $self = shift;
    my $indent = shift || 0;
    my $width = 72 - $indent;
    
    my $type = $self->type;
    my $body = $self->body;
    if(my $body_attr = $self->param('body_attr')) {
        $body = $self->param($body_attr)->pod;
    }
    $body =~ s/[\n\t]//g if $body;
    
    my $r = ' ' x $indent;
    if($body) {
        $r .= substr("[$type] $body",0,$width);
    } else {
        $r .= "[$type]";
    }
    $r = sprintf("%3d %s",$self->serial, $r);
    $r .= "\n";
    my @children = $self->children;
    foreach my $c (@children) {
        $r .= $c->ptree($indent + 2);
    }
    return $r;
}

sub pod {
    my $self = shift;
    
    my $r = '';
    my $body = $self->body;
    my $type = $self->type;
    my $should_para_break = 0;
    my $p_break = $self->param('p_break');
    $p_break = "\n\n" unless defined $p_break;
    
    my $r_delim = undef; # Used if a interior sequence needs closing.

    if($type eq ':paragraph') {
        $should_para_break = 1;
    } elsif( $type eq ':text' or $type eq '#cut' or $type eq ':verbatim') {
        $r .= $body;
    } elsif( $type =~ m/^\:(.+)$/ ) { # Interior sequence
        my $cmd = $1;
        my $l_delim = $self->param('left_delimiter');
        $r_delim = $self->param('right_delimiter');
        $r .= "$cmd$l_delim";
    } elsif( $type eq '[ROOT]' or $type =~ m/^@/) {
        # ignore
    } else { # command
        my $body_attr = $self->param('body_attr');
        if($body_attr) {
            $body = $self->param($body_attr)->pod;
        }
        
        $r .= "=$type $body$p_break";
    }
    
    my @children = $self->children;
    foreach my $c (@children) {
        $r .= $c->pod;
    }
    
    if($should_para_break) {
        $r .= $p_break;
    } elsif($r_delim) {
        $r .= $r_delim;
    }
    
    if($self->param('close_element')) {
        $r .= $self->param('close_element')->pod;
    }
    
    return $r;
}

sub select {
    my $self = shift;
    my $path = shift;
    
    my $p_path = Pod::Abstract::Path->new($path);
    return $p_path->process($self);
}

sub select_into {
    my $self = shift;
    my $target = shift;
    my $path = shift;
    
    my @nodes = $self->select($path);
    my @dup_nodes = map { $_->duplicate } @nodes;
    
    $target->nest(@dup_nodes);
}

sub type {
    my $self = shift;
    if(@_) {
        my $new_val = shift;
        $self->{type} = $new_val;
    }
    return $self->{type};
}

sub body {
    my $self = shift;
    if(@_) {
        my $new_val = shift;
        $self->{body} = $new_val;
    }
    return $self->{body};
}

sub param {
    my $self = shift;
    my $param_name = shift;
    if(@_) {
        my $new_val = shift;
        $self->{params}{$param_name} = $new_val;
    }
    return $self->{params}{$param_name};
}

sub duplicate {
    my $self = shift;
    my $class = ref $self;
 
    # Implement the new() call with all the data needed.
    my $params = $self->{params};
    my %new_params = ( );
    foreach my $param (keys %$params) {
        my $pv = $params->{$param};
        if(ref $pv && UNIVERSAL::can($pv, 'duplicate')) {
            $new_params{$param} = $pv->duplicate;
        } elsif(! ref $pv) {
            $new_params{$param} = $pv;
        } else {
            die "Don't know how to copy a ", ref $pv;
        }
    }
    my $dup = $class->new(
        type => $self->type,
        body => $self->body,
        %new_params,
        );
    
    my @children = $self->children;
    my @dup_children = map { $_->duplicate } @children;
    $dup->nest(@dup_children);
    
    return $dup;
}

sub insert_before {
    my $self = shift;
    my $target = shift;
    
    my $target_tree = $target->parent->tree;
    die "Can't insert before a root node" unless $target_tree;
    if($target_tree->insert_before($target, $self)) {
        $self->parent($target->parent);
    } else {
        die "Could not insert before [$target]";
    }
}

sub insert_after {
    my $self = shift;
    my $target = shift;
    
    my $target_tree = $target->parent->tree;
    die "Can't insert after a root node" unless $target_tree;
    if($target_tree->insert_after($target, $self)) {
        $self->parent($target->parent);
    } else {
        die "Could not insert before [$target]";
    }
}

sub hoist {
    my $self = shift;
    my @children = $self->children;
    
    my $parent = $self->parent;

    my $target = $self;
    foreach my $n(@children) {
        $n->detach;
        $n->insert_after($target);
        $target = $n;
    }
    
    return scalar @children;
}

sub clear {
    my $self = shift;
    my @children = $self->children;
    
    foreach my $n (@children) {
        $n->detach;
    }
    
    return @children;
}

sub push {
    my $self = shift;
    my $target = shift;
    
    my $target_tree = $self->tree;
    if($target_tree->push($target)) {
        $target->parent($self);
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
        $target->parent($self);
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
