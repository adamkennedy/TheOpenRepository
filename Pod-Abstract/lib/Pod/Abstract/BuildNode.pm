package Pod::Abstract::BuildNode;
use strict;

use Exporter;
use Pod::Abstract;
use Pod::Abstract::Parser;
use Pod::Abstract::Node;
use base qw(Exporter);

our @EXPORT_OK = qw(node nodes);
use constant {
    node  => 'Pod::Abstract::BuildNode',
    nodes => 'Pod::Abstract::BuildNode',
};

sub pod {
    my $class = shift;
    my $str = shift;
    
    my $root = Pod::Abstract->load_string($str);
    
    my @r = map { $_->detach } $root->children;
    return @r;
}

sub paragraph {
    my $class = shift;
    my $str = shift;
    
    my $para = Pod::Abstract::Node->new(
        type => ':paragraph',
        );
    my $parser = Pod::Abstract::Parser->new;
    my $pt = $parser->parse_text($str);
    if($pt) {
        $parser->load_pt($para,$pt);
    } else {
        return undef;
    }
}

sub verbatim {
    my $class = shift;
    my $str = shift;
    
    my @strs = split $str, '\n';
    for(my $i = 0; $i < @strs; $i ++) {
        $strs[$i] = ' '.$strs[$i];
    }
    my $verbatim = Pod::Abstract::Node->new(
        type => ':verbatim',
        body => join('\n', @strs),
        );
    return $verbatim;
}

sub heading {
    my $class = shift;
    my $level = shift;
    my $heading = shift;

    my $attr_node = Pod::Abstract::Node->new(
        type => '@attribute',
        body => 'heading',
        );
    my $parser = Pod::Abstract::Parser->new;
    my $pt = $parser->parse_text($heading);
    $parser->load_pt($attr_node, $pt);
        
    my $element_node = Pod::Abstract::Node->new(
        type => "head$level",
        heading => $attr_node,
        body_attr => 'heading',
        );
    return $element_node;
}

sub head1 {
    my $class = shift;
    my $heading = shift;
    
    return $class->heading(1,$heading);
}

sub head2 {
    my $class = shift;
    my $heading = shift;
    
    return $class->heading(2,$heading);
}

sub head3 {
    my $class = shift;
    my $heading = shift;
    
    return $class->heading(3,$heading);
}

sub head4 {
    my $class = shift;
    my $heading = shift;
    
    return $class->heading(4,$heading);
}

sub over {
    my $class = shift;
    my $number = shift;
    $number = '' unless defined $number;
    
    return Pod::Abstract::Node->new(
        type => 'over',
        body => $number,
        close_element => Pod::Abstract::Node->new(
            type => 'back',
            body => '',
        ),
        );
}

sub item {
    my $class = shift;
    my $label = shift;
    
    my $attr_node = Pod::Abstract::Node->new(
        type => '@attribute',
        body => 'label',
        );
    my $parser = Pod::Abstract::Parser->new;
    my $pt = $parser->parse_text($label);
    $parser->load_pt($attr_node, $pt);
        
    my $element_node = Pod::Abstract::Node->new(
        type => "item",
        label => $attr_node,
        body_attr => 'label',
        );
    return $element_node;
}

sub text {
    my $class = shift;
    my $text = shift;
    
    my $attr_node = Pod::Abstract::Node->new(
        type => ':text',
        body => $text,
        );
    return $attr_node;
}

1;
