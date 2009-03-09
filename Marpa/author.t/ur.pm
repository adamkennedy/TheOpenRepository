#!perl
# An ambiguous equation

use 5.010;
use strict;
use warnings;

use Carp;
use Marpa;
use Data::Dumper;

my $grammar = new Marpa::Grammar(
    {   start => 'display_or_commands',

        rules => [
            {   lhs    => 'display_or_commands',
                rhs    => ['display'],
                action => '{ display => $_[0] }'
            },
            {   lhs    => 'display_or_commands',
                rhs    => ['commands'],
                action => '{ commands => $_[0] }'
            },
            {   lhs    => 'display_or_commands',
                rhs    => [qw(commands display)],
                action => '{ commands => $_[0], display => $_[1] }'
            },
            {   lhs    => 'commands',
                rhs    => [ 'begin line', 'instructions', 'end line' ],
                action => '{ $_[1] }'
            },
            {   lhs => 'instructions',
                rhs => ['command'],
                min => 1
            },
            {   lhs    => 'command',
                rhs    => ['partial command'],
                action => '{ partial => 1 }'
            },
            {   lhs    => 'command',
                rhs    => ['file command'],
                action => '{ file => $_[0] }'
            },
            {   lhs    => 'command',
                rhs    => ['name command'],
                action => '{ name => $_[0] }'
            },
            {   lhs    => 'command',
                rhs    => ['ignore whitespace command'],
                action => '{ ignore_whitespace => $_[0] }'
            },
            {   lhs    => 'command',
                rhs    => ['default command'],
                action => '{ default => $_[0] }'
            },
            {   lhs => 'display',
                rhs => ['display line'],
                min => 1
            },
            [ 'display line', ['whitespace'],    '$_[0]' ],
            [ 'display line', ['indented line'], '$_[0]' ],
        ],

        terminals => [
            'whitespace',
            'indented line',
            'begin line',
            'end line',
            'ignore whitespace command',
            'name command',
            'partial command',
            'default command',
            'file command',
            'other line',
        ],

        inaccessible_ok => [ 'other line' ],

    }
);

$grammar->precompute();

my $instruction = $grammar->get_symbol('whitespace');
my $indented_line = $grammar->get_symbol('indented line');
my $begin_line = $grammar->get_symbol('begin line');
my $end_line = $grammar->get_symbol('end line');
my $name_command = $grammar->get_symbol('name command');
my $file_command = $grammar->get_symbol('file command');
my $partial_command = $grammar->get_symbol('partial command');
my $default_command = $grammar->get_symbol('default command');
my $ignore_whitespace_command = $grammar->get_symbol('ignore whitespace command');
my $whitespace = $grammar->get_symbol('whitespace');
my $other_line = $grammar->get_symbol('other line');

my $recce = new Marpa::Recognizer({grammar => $grammar});

my $active = 0;
my $line_number = 0;

TOKEN: while ( my $line = <STDIN> ) {
    $line_number++;
    print "$line_number: $line";
    chomp $line;

    my $value = q{};
    my $token = $other_line;

    LINE_TEST: {
        if ( $line
            =~ /\A [=] begin \s+ Marpa[:][:]Test[:][:]Display[:] \s* .* \z/xms
            )
        {
            print "BEGIN: $line\n";
            $token = $begin_line;
            last LINE_TEST;
        }
        if ( $line
            =~ /\A [=] end \s+ Marpa[:][:]Test[:][:]Display[:] \s* \z/xms )
        {
            print "END: $line\n";
            $token = $end_line;
            last LINE_TEST;
        }
        if ( $line =~ /\A \s* \z/xms ) {
            print "WHITESPACE\n";
            $token = $whitespace;
            last LINE_TEST;
        }
        if ( $line =~ /\A \s* partial \s* \z/xms ) {
            print "PARTIAL COMMAND: $line\n";
            $token = $partial_command;
            last LINE_TEST;
        }
        if ( $line =~ /\A \s* default \s* \z/xms ) {
            print "DEFAULT COMMAND: $line\n";
            $token = $default_command;
            last LINE_TEST;
        }
        if ( $line =~ /\A \s* file \s+ (.*\S) \s* \z/xms ) {
            $value = $1;
            print "FILE COMMAND: $value\n";
            $token = $file_command;
            last LINE_TEST;
        }
        if ( $line =~ /\A \s* name \s+ (.*\S) \s* \z/xms ) {
            $value = $1;
            print "NAME COMMAND: $value\n";
            $token = $name_command;
            last LINE_TEST;
        }
        if ( $line =~ /\A \s* ignore \s+ whitespace \s* \z/xms ) {
            print "IGNORE WHITESPACE COMMAND\n";
            $token = $ignore_whitespace_command;
            last LINE_TEST;
        }
        if ( $line =~ /\A \s+ .* \z/xms ) {
            $value = $line;
            print "INDENTED LINE: $value\n";
            $token = $indented_line;
            last LINE_TEST;
        }
    }    # LINE_TEST

    my $now_active = $recce->earleme( [ $token, $value, 1 ] );

    # on active to exhausted transition, produce a parse
    if ($active and not $now_active) {
        $recce->end_input();
        my $evaler = new Marpa::Evaluator( { recce => $recce, } );
        print Dumper ( $evaler->value());
    }

    # if not now active, create a new recognizer
    if (not $now_active) {
        $recce = new Marpa::Recognizer({grammar => $grammar});
    }

    $active = $now_active;

} continue {
}

exit 0;



# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
