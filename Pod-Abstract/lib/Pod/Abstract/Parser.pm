package Pod::Abstract::Parser;
use strict;

use Pod::Parser;
use Pod::Abstract::Node;
use Data::Dumper;
use base qw(Pod::Parser);

=head1 new

 Pod::Abstract::Parser->new( $pod_abstract );

Requires a Pod::Abstract object to load Pod data into. Should only be
called internally by Pod::Abstract.

=cut

sub new {
    my $class = shift;
    my $p_a = shift;
    
    # Always accept non-POD paras, so that the input document can
    # always be reproduced exactly as entered. These will be stored in
    # the tree but will be available through distinct methods.
    my $self = $class->SUPER::new();
    $self->parseopts(
        -want_nonPODs => 1,
        -process_cut_cmd => 1,
        );
    $self->{pod_abstract} = $p_a;
    my $root_node = Pod::Abstract::Node->new(
        type => "[ROOT]",
        );
    $self->{cmd_stack} = [ $root_node ];
    $self->{root} = $root_node;
    
    return $self;
}

sub root {
    my $self = shift;
    return $self->{root};
}

# Automatically nest these items: A head1 section continues until the
# next head1, list items continue until the next item or end of list,
# etc. POD doesn't specify these relationships, but they are natural
# and make sense in the whole document context.
my %section_commands = (
    'head1' => [ 'head1' ],
    'head2' => [ 'head2', 'head1' ],
    'head3' => [ 'head3', 'head2', 'head1' ],
    'head4' => [ 'head4', 'head3', 'head2', 'head1' ],
    'over'  => [ 'back' ],
    'item'  => [ 'item', 'back' ],
    );

my %attr_names = (
    head1 => 'heading',
    head2 => 'heading',
    head3 => 'heading',
    head4 => 'heading',
    item  => 'label',
    );

sub command {
    my ($self, $command, $paragraph, $line_num) = @_;
    my $cmd_stack = $self->{cmd_stack} || [ ];
    chomp $paragraph; chomp $paragraph;
    
    if($self->cutting) {
        # Treat as non-pod - i.e, verbatim program text block.
        my $element_node = Pod::Abstract::Node->new(
            type => "#cut",
            body => "=$command $paragraph\n\n",
            );
        my $top = $cmd_stack->[$#$cmd_stack];
        $top->push($element_node);
    } else {
        # Treat as command.
        while(@$cmd_stack > 0) {
            my $last = scalar(@$cmd_stack) - 1;
            my @should_end = ( );
            @should_end = 
                grep { $command eq $_ }
                     @{$section_commands{$cmd_stack->[$last]->type}};
            if(@should_end) {
                my $end_cmd = pop @$cmd_stack;
            } else {
                last;
            }
        }
        
        # Some commands have to get expandable interior sequences
        my $attr_node = undef;
        my $attr_name = $attr_names{$command};
        my %attr = ( );
        if($attr_name) {
            $attr_node = Pod::Abstract::Node->new(
                type => '@attribute',
                body => $attr_name,
                );
            my $pt = $self->parse_text($paragraph);
            $self->load_pt($attr_node, $pt);
            $attr{$attr_name} = $attr_node;
            $attr{body_attr} = $attr_name;
        }
        
        my $element_node = Pod::Abstract::Node->new(
            type => $command,
            body => ($attr_name ? $paragraph : ''),
            %attr,
            );
        my $top = $cmd_stack->[$#$cmd_stack];
        $top->push($element_node);
        if($section_commands{$command}) {
            push @$cmd_stack, $element_node;
        } else {
            # No push
        }
    }
    
    $self->{cmd_stack} = $cmd_stack;
}

sub verbatim {
    my ($self, $paragraph, $line_num) = @_;
    chomp $paragraph; chomp $paragraph;
    
    my $element_node = Pod::Abstract::Node->new(
        type => ':verbatim',
        body => $paragraph,
        );
    my $cmd_stack = $self->{cmd_stack};
    my $top = $cmd_stack->[$#$cmd_stack];
    $top->push($element_node);
}

sub preprocess_paragraph {
    my ($self, $text, $line_num) = @_;
    return $text unless $self->cutting;
    
    # This is a non-pod text segment
    my $element_node = Pod::Abstract::Node->new(
        type => "#cut",
        body => $text,
        );
    my $cmd_stack = $self->{cmd_stack};
    my $top = $cmd_stack->[$#$cmd_stack];
    $top->push($element_node);
}

sub textblock {
    my ($self, $paragraph, $line_num) = @_;
    chomp $paragraph; chomp $paragraph;

    my $element_node = Pod::Abstract::Node->new(
        type => ':paragraph',
        );
    my $pt = $self->parse_text($paragraph);
    $self->load_pt($element_node, $pt);

    my $cmd_stack = $self->{cmd_stack};
    my $top = $cmd_stack->[$#$cmd_stack];
    $top->push($element_node);
}

# Recursive load
sub load_pt {
    my $self = shift;
    my $elt = shift;
    my $pt = shift;
    
    my @c = $pt->children;
    foreach my $c(@c) {
        if(ref $c) {
            # Object;
            if($c->isa('Pod::InteriorSequence')) {
                my $cmd = $c->cmd_name;
                my $i_node = Pod::Abstract::Node->new(
                    type => ":$cmd",
                    left_delimiter => $c->left_delimiter,
                    right_delimiter => $c->right_delimiter,
                    );
                $self->load_pt($i_node, $c->parse_tree);
                $elt->push($i_node);
            } else {
                die "$c not an interior sequence!";
            }
        } else {
            # text
            my $t_node = Pod::Abstract::Node->new(
                type => ':text',
                body => $c,
                );
            $elt->push($t_node);
        }
    }
    return $elt;
}

sub end_pod {
    my $self = shift;
    my $cmd_stack = $self->{cmd_stack};
    
    my $end_cmd;
    while(defined $cmd_stack && @$cmd_stack) {
        $end_cmd = pop @$cmd_stack;
    }
    die "Last node was not root node" unless $end_cmd->type eq '[ROOT]';
    
    # Replace the root node.
    push @$cmd_stack, $end_cmd;
}

1;
