package Marpa::Example::Equation;

## no critic (Subroutines::RequireArgUnpacking)

sub op {
    my ( $right_string, $right_value ) = ( $_[2] =~ /^(.*)==(.*)$/ );
    my ( $left_string,  $left_value )  = ( $_[0] =~ /^(.*)==(.*)$/ );
    my $op = $_[1];
    my $value;
    if ( $op eq "+" ) {
        $value = $left_value + $right_value;
    }
    elsif ( $op eq "*" ) {
        $value = $left_value * $right_value;
    }
    elsif ( $op eq "-" ) {
        $value = $left_value - $right_value;
    }
    else {
        Marpa::exception("Unknown op: $op");
    }
    return '(' . $left_string . $op . $right_string . ')==' . $value;
} ## end sub op

sub number {
    my $v0 = pop @_;
    return $v0 . q{==} . $v0;
}

sub default_action {
    my $v_count = scalar @_;
    return "" if $v_count <= 0;
    return $_[0] if $v_count == 1;
    return '(' . join( q{;}, @_ ) . ')';
} ## end sub default_action

## use critic

1;
