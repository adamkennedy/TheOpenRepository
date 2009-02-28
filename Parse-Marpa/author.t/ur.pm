#!perl
# An ambiguous equation

use 5.010;
use strict;
use warnings;

use Carp;
use Parse::Marpa;

my $grammar = new Parse::Marpa::Grammar({
    start => 'program',

    rules => [
        {   lhs    => 'program',
            rhs    => ['stretch'],
            min    => 1,
            action => '\@_'
        },
        [ 'stretch', [qw/display/],     '$_[0]' ],
        [ 'stretch', [qw/other lines/], '$_[0]' ],
        [   'display', [ 'begin line', 'instruction lines', 'end line' ],
            '$_[1]'
        ],
        {   lhs => 'instructions',
            rhs => ['instruction'],
            min => 1
        },
        {   lhs => 'other lines',
            rhs => ['other line'],
            min => 1,
        },
        ],

    default_action =>
<<'EO_CODE',
     my $v_count = scalar @_;
     return q{} if $v_count <= 0;
     return $_[0] if $v_count == 1;
     '(' . join(q{;}, @_) . ')';
EO_CODE

});

$grammar->precompute();

my $recce = new Parse::Marpa::Recognizer({grammar => $grammar});

my $instruction = $grammar->get_symbol('instruction');
my $other = $grammar->get_symbol('other line');
my $begin = $grammar->get_symbol('begin line');
my $end = $grammar->get_symbol('end line');

TOKEN: while (my $line = <STDIN>) {
    chomp $line;
    if ( $line =~ /\A [=] begin \s+ Marpa[:][:]Test[:][:]Display[:] \s* .* \z/xms )
    {
       print "BEGIN: $line\n";
    }
    if ( $line =~ /\A [=] end \s+ Marpa[:][:]Test[:][:]Display[:] \s* \z/xms )
    {
       print "END: $line\n";
    }
    if ( $line =~ /\A \s* \z/xms )
    {
       print "WHITESPACE\n";
    }
    if ( $line =~ /\A \s* partial \s* \z/xms )
    {
       print "PARTIAL COMMAND: $line\n";
    }
    if ( $line =~ /\A \s* file \s* \z/xms )
    {
       print "FILE COMMAND: $line\n";
    }
    if ( $line =~ /\A \s* name \s* \z/xms )
    {
       print "NAME COMMAND: $line\n";
    }
    if ( $line =~ /\A \s* ignore \s+ whitespace \s* \z/xms )
    {
       print "IGNORE WHITESPACE COMMAND: $line\n";
    }
    # next TOKEN if $recce->earleme($token);
    # croak('Parsing exhausted at character: ', $token->[1]);
}

exit 0;

$recce->end_input();

my $evaler = new Parse::Marpa::Evaluator( { recce => $recce, } );

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
