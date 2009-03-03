package Pod::Abstract::Path;
use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Indent = 1;

our $VERSION = '0.14';

use constant {
    CHILDREN  => 1,  # /
    ALL       => 2,  # //
    NAME      => 3,  # head1
    INDEX     => 4,  # (3)
    L_SELECT  => 5,  # [
    ATTR      => 6,  # @label
    EQUAL     => 7,  # =
    STRING    => 8,  # 'foobar'
    R_SELECT  => 9,  # ]
    NOT_EQ    => 10, # <>
    LESS_THAN => 11, # <
    LESS_EQ   => 12, # <=
    GT_THAN   => 13, # >
    GT_EQ     => 14, # >=
    NOT       => 15, # !
    PARENT    => 16, # ..
    MATCHES   => 17, # =~
    REGEXP    => 18, # {<pattern>}
    NOP       => 19, # .
    PREV      => 20, # <<
    NEXT      => 21, # >>
};

=pod

=head1 NAME

POD::Abstract::Path - Search for POD nodes matching a path within a
document tree.

=head1 SYNOPSIS

 /head1.1/head2     # All head2 elements under the 2nd head1 element
 //item             # All items anywhere
 //item[@label='*'] # All items with '*' labels.
 //head2[hilight]   # All head2 elements containing "hilight" elements

=cut

sub new {
    my $class = shift;
    my $expression = shift;
    my $parse_tree = shift;
    
    if($parse_tree) {
        my $self = bless { 
            expression => $expression,
            parse_tree => $parse_tree
        }, $class;
        return $self;
    } else {
        my $self = bless { expression => $expression }, $class;
        
        my @lexemes = $self->lex($expression);
        my $parse_tree = $self->parse_path(\@lexemes);
        $self->{parse_tree} = $parse_tree;
        
        return $self;
    }
}

sub lex {
    my $self = shift;
    my $expression = shift;
    my @l = ( );

    # Get rid of white space
    $expression =~ s/[ \t\n\r]+//g;

    # Digest expression into @l
    while($expression) {
        if($expression =~ m/^\/\//) {
            substr($expression,0,2) = '';
            push @l, [ ALL, undef ];
        } elsif($expression =~ m/^\//) {
            substr($expression,0,1) = '';
            push @l, [ CHILDREN, undef ];
        } elsif($expression =~ m/^\[/) {
            substr($expression,0,1) = '';
            push @l, [ L_SELECT, undef ];
        } elsif($expression =~ m/^\]/) {
            substr($expression,0,1) = '';
            push @l, [ R_SELECT, undef ];
        } elsif($expression =~ m/^([#_\:a-zA-Z0-9]+)/) {
            push @l, [ NAME, $1 ];
            substr($expression, 0, length $1) = '';
        } elsif($expression =~ m/^\@([a-zA-Z0-9]+)/) {
            push @l, [ ATTR, $1 ];
            substr($expression, 0, length( $1 ) + 1) = '';
        } elsif($expression =~ m/^\(([0-9]+)\)/) {
            push @l, [ INDEX, $1 ];
            substr($expression, 0, length( $1 ) + 2) = '';
        } elsif($expression =~ m/^\{(([^\}]|\\\})+)\}/) {
            push @l, [ REGEXP, $1 ];
            substr($expression, 0, length( $1 ) + 2) = '';
        } elsif($expression =~ m/^'(([^']|\\')+)'/) {
            push @l, [ STRING, $1 ];
            substr($expression, 0, length( $1 ) + 2) = '';
        } elsif($expression =~ m/^\=\~/) {
            push @l, [ MATCHES, undef ];
            substr($expression, 0, 2) = '';
        } elsif($expression =~ m/^\.\./) {
            push @l, [ PARENT, undef ];
            substr($expression, 0, 2) = '';            
        } elsif($expression =~ m/^\./) {
            push @l, [ NOP, undef ];
            substr($expression, 0, 1) = '';
        } elsif($expression =~ m/^\!/) {
            push @l, [ NOT, undef ];
            substr($expression, 0, 1) = '';
        } elsif($expression =~ m/^\<\</) {
            push @l, [ PREV, undef ];
            substr($expression, 0, 2) = '';
        } elsif($expression =~ m/^\>\>/) {
            push @l, [ NEXT, undef ];
            substr($expression, 0, 2) = '';
        } else {
            die "Invalid token encountered - remaining string is $expression";
        }
    }
    return @l;
}

# Rec descent process of expression.
sub process {
    my $self = shift;
    my @nodes = @_;
    
    my $pt = $self->{parse_tree};
    my $ilist = [ @nodes ];
    
    while($pt && $pt->{action} ne 'end_select') {
        my $action = $pt->{action};
        my @args = ( );
        if($pt->{arguments}) {
            @args = @{$pt->{arguments}};
        }
        if($self->can($action)) {
            $ilist = $self->$action($ilist, @args);
        } else {
            warn "discarding '$action', can't do that";
        }
        $pt = $pt->{'next'};
    }
    return @$ilist;
}

sub select_name {
    my $self = shift;
    my $ilist = shift;
    my $name = shift;
    my $nlist = [ ];
    
    for(my $i = 0; $i < @$ilist; $i ++) {
        if($ilist->[$i]->type eq $name) {
            push @$nlist, $ilist->[$i];
        };
    }
    return $nlist;
}

sub select_attr {
    my $self = shift;
    my $ilist = shift;
    my $name = shift;
    my $nlist = [ ];
    
    foreach my $i (@$ilist) {
        my $pv = $i->param($name);
        if($pv) {
            push @$nlist, $pv;
        }
    }
    return $nlist;
}

sub select_index {
    my $self = shift;
    my $ilist = shift;
    my $index = shift;
    
    if($index < scalar @$ilist) {
        return [ $ilist->[$index] ];
    } else {
        return [ ];
    }
}

sub match_expression {
    my $self = shift;
    my $ilist = shift;
    my $test_action = shift;
    my $invert = shift;
    my $exp = shift;
    my $r_exp = shift;
    
    my $nlist = [ ];
    foreach my $n(@$ilist) {
        my @t_list = $exp->process($n);
        my $t_result = $self->$test_action(\@t_list, $r_exp);
        $t_result = !$t_result if $invert;
        if($t_result) {
            push @$nlist, $n;
        }
    }
    return $nlist;
}

sub test_regexp {
    my $self = shift;
    my $t_list = shift;
    my $regexp = shift;
    $regexp = qr/$regexp/;
    my $nlist = [ ];

    my $match = 0;
    foreach my $t_n (@$t_list) {
        my $body = $t_n->body;
        $body = $t_n->pod unless defined $body;
        if($body =~ $regexp) {
            $match ++;
        }
    }
    return $match;
}

sub test_simple {
    my $self = shift;
    my $t_list = shift;
    
    return (scalar @$t_list) > 0;
}

sub select_children {
    my $self = shift;
    my $ilist = shift;
    my $nlist = [ ];
    
    foreach my $n (@$ilist) {
        my @children = $n->children;
        push @$nlist, @children;
    }
    
    return $nlist;
}

sub select_next {
    my $self = shift;
    my $ilist = shift;
    my $nlist = [ ];
    
    foreach my $n (@$ilist) {
        my $next = $n->next;
        if($next) {
            push @$nlist, $next;
        }
    }
    
    return $nlist;
}

sub select_prev {
    my $self = shift;
    my $ilist = shift;
    my $nlist = [ ];
    
    foreach my $n (@$ilist) {
        my $prev = $n->previous;
        if($prev) {
            push @$nlist, $prev;
        }
    }
    
    return $nlist;
}

sub select_parents {
    my $self = shift;
    my $ilist = shift;
    my $nlist = [ ];
    foreach my $n (@$ilist) {
        if($n->parent) {
            push @$nlist, $n->parent;
        }
    }
    
    return $nlist;
}

sub select_current {
    my $self = shift;
    my $ilist = shift;
    return $ilist;
}

sub select_all {
    my $self = shift;
    my $ilist = shift;
    my $nlist = [ ];
    
    foreach my $n (@$ilist) {
        push @$nlist, $self->expand_all($n);
    }
    
    return $nlist;
}

sub expand_all {
    my $self = shift;
    my $n = shift;
    
    my @children = $n->children;
    my @r = ( );
    foreach my $c (@children) {
        push @r, $c;
        push @r, $self->expand_all($c);
    };
    
    return @r;
}

=head1 parse_path

Parse a list of lexemes and generate a driver tree for the process
method. This is a simple recursive descent parser with one element of
lookahead.

=cut

sub parse_path {
    my $self = shift;
    my $l = shift;
    
    my $next = shift @$l;
    my $tok = $next->[0] if $next;
    my $val = $next->[1] if $next;
    
    # Accept: / (children), // (all), name, <select>, @attr, .index
    if(not defined $next) {
        return {
            'action' => 'end_select',
        };
    } elsif($tok == MATCHES or $tok == R_SELECT ) {
        unshift @$l, $next;
        return {
            'action' => 'end_select',
        };
    } elsif($tok == CHILDREN) {
        return { 
            'action' => 'select_children',
            'next' => $self->parse_path($l),
        };
    } elsif($tok == ALL) {
        return {
            'action' => 'select_all',
            'next' => $self->parse_path($l),
        };
    } elsif($tok == NEXT) {
        return {
            'action' => 'select_next',
            'next' => $self->parse_path($l),
        };
    } elsif($tok == PREV) {
        return {
            'action' => 'select_prev',
            'next' => $self->parse_path($l),
        };
    } elsif($tok == PARENT) {
        return {
            'action' => 'select_parents',
            'next' => $self->parse_path($l),
        };
    } elsif($tok == NOP) {
        return {
            'action' => 'select_current',
            'next' => $self->parse_path($l),
        };
    } elsif($tok == NAME) {
        return {
            'action' => 'select_name',
            'arguments' => [ $val ],
            'next' => $self->parse_path($l),
        };
    } elsif($tok == ATTR) {
        return {
            'action' => 'select_attr',
            'arguments' => [ $val ],
            'next' => $self->parse_path($l),
        };
    } elsif($tok == INDEX) {
        return {
            'action' => 'select_index',
            'arguments' => [ $val ],
            'next' => $self->parse_path($l),
        };
    } elsif($tok == L_SELECT) {
        unshift @$l, $next;
        my $exp = $self->parse_expression($l);
        $exp->{'next'} = $self->parse_path($l);
        return $exp;
    } elsif($tok == ATTR) {
        return {
            'action' => 'select_attribute',
            'arguments' => [ $val ],
            'next' => $self->parse_path($l),
        }
    } else {
        die "Unexpected token, ", Dumper([$next]);
    }
}

sub parse_expression {
    my $self = shift;
    my $class = ref $self;
    my $l = shift;
    
    my $l_select = shift @$l;
    die "Expected L_SELECT, got ", Dumper([$l_select])
        unless $l_select->[0] == L_SELECT;
    
    # See if we lead with a NOT
    if($l->[0][0] == NOT) {
        shift @$l;
        unshift @$l, $l_select;
        
        my $exp = $self->parse_expression($l);
        $exp->{arguments}[1] = !$exp->{arguments}[1];
        return $exp;
    }
        
    
    my $l_exp = $self->parse_path($l);
    $l_exp = $class->new("select expression",$l_exp);
    my $op = shift @$l;
    my $op_tok = $op->[0];
    my $exp = undef;
    
    if($op_tok == MATCHES) {
        my $re = shift @$l;
        my $re_tok = $re->[0];
        my $re_str = $re->[1];
        
        if($re_tok == REGEXP) {
            $exp = {
                'action' => 'match_expression',
                'arguments' => [ 'test_regexp', 0, $l_exp, $re_str ],
            }
        } else {
            die "Expected REGEXP, got ", Dumper([$re_tok]);
        }
    } elsif($op_tok == R_SELECT) {
        # simple expression
        unshift @$l, $op;
        $exp = {
            'action' => 'match_expression',
            'arguments' => [ 'test_simple', 0, $l_exp ],
        }
    } else {
        die "Expected MATCHES, got ", Dumper([$op_tok]);
    }
    
    # Must match close of select;
    my $r_select = shift @$l;
    die "Expected R_SELECT, got, ", Dumper([$r_select])
        unless $r_select->[0] == R_SELECT;
    die "Failed to generate expression"
        unless $exp;
    
    # All OK!
    return $exp;
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
 
