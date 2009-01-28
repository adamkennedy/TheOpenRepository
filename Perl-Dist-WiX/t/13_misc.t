#!perl

use strict;
use warnings;
use Test::More tests=> 15;
use Test::Output;
use Perl::Dist::WiX::Misc;

# Tests 1-3: indent

my $misc = Perl::Dist::WiX::Misc->new(trace => 5);

ok($misc, '->new returns true');
is($Perl::Dist::WiX::Misc::VERSION, '0.11_07', 'Version correct');

my $string = "testing\nindent";
is($misc->indent(2, $string), "  testing\n  indent", 'indent');

# Tests 4-5: indent errors

eval { $misc->indent(1, q[]); };

like( $@, qr(Missing or invalid string), 'indent prints string error');

eval { $misc->indent(-1, q[ ]); };

like( $@ , qr(Missing or invalid num), 'indent prints integer error');

# Test 6-12: trace_line

stdout_like( sub { $misc->trace_line(1, "Test 6\n") }, 
    qr(\A\Q[1] [13_misc.t 31] Test 6\E\n\z), 
    'trace_line works at level 5'
);

$misc->{trace} = 3;

stdout_like( sub { $misc->trace_line(1, "Test 7\n") }, 
    qr(\A\Q[1] Test 7\E\n\z), 
    'trace_line works at level 3'
);

$misc->{trace} = 1;

stdout_like( sub { $misc->trace_line(1, "Test 8\n") }, 
    qr(\ATest 8\n\z), 
    'trace_line works at level 1'
);

$misc->{trace} = 0;

stdout_like( sub { $misc->trace_line(1, "Test 9\n") }, 
    qr(\A\z), 
    'trace_line works (not printing) at level 0'
);

stderr_like( sub { $misc->trace_line(0, "Test 10\n") }, 
    qr(\ATest 10\n\z), 
    'trace_line works (printing to stderr) at level 0'
);

$misc->{trace} = 2;

stdout_like( sub { $misc->trace_line(1, "Test 11\n", 1) }, 
    qr(\ATest 11\n\z), 
    'trace_line works (no_display true) at level 2'
);

stdout_like( sub { $misc->trace_line(1, "Test 12a\nTest 12b\n") }, 
    qr(\A\Q[1]\E Test 12a\n\Q[1]\E Test 12b\n\z), 
    'trace_line works (multiline) at level 2'
);


# Tests 13-15: trace_line errors

eval { $misc->trace_line(-1, q[ ]); };

like( $@, qr(Missing or invalid tracelevel), 'trace_line prints tracelevel error');

eval { $misc->trace_line(1, q[]); };

like( $@ , qr(Missing or invalid text), 'trace_line prints text error');

$misc->{trace} = -1;

eval { $misc->trace_line(1, "Error 5\n"); };

like( $@ , qr(Inconsistent trace state), 'trace_line prints inconsistent state error');

