#!perl

use strict;
use warnings;
use Test::More tests=> 14;
use Test::Output;
use Perl::Dist::WiX::Misc;

# Tests 1-2: indent

my $misc = Perl::Dist::WiX::Misc->new(trace => 5);

ok($misc, '->new returns true');

my $string = "testing\nindent";
is($misc->indent(2, $string), "  testing\n  indent", 'indent');

# Tests 3-4: indent errors

eval { $misc->indent(1, q[]); };

like( $@, qr(invalid: string), 'indent prints string error');

eval { $misc->indent(-1, q[ ]); };

like( $@ , qr(invalid: num), 'indent prints integer error');

# Test 5-11: trace_line

stdout_like( sub { $misc->trace_line(1, "Test 5\n") }, 
    qr(\A\Q[1] [02_misc.t 30] Test 5\E\n\z), 
    'trace_line works at level 5'
);

$misc->set_trace(3);

stdout_like( sub { $misc->trace_line(1, "Test 6\n") }, 
    qr(\A\Q[1] Test 6\E\n\z), 
    'trace_line works at level 3'
);

$misc->set_trace(1);

stdout_like( sub { $misc->trace_line(1, "Test 7\n") }, 
    qr(\ATest 7\n\z), 
    'trace_line works at level 1'
);

$misc->set_trace(0);

stdout_like( sub { $misc->trace_line(1, "Test 8\n") }, 
    qr(\A\z), 
    'trace_line works (not printing) at level 0'
);

stderr_like( sub { $misc->trace_line(0, "Test 9\n") }, 
    qr(\ATest 9\n\z), 
    'trace_line works (printing to stderr) at level 0'
);

$misc->set_trace(2);

stdout_like( sub { $misc->trace_line(1, "Test 10\n", 1) }, 
    qr(\ATest 10\n\z), 
    'trace_line works (no_display true) at level 2'
);

stdout_like( sub { $misc->trace_line(1, "Test 11a\nTest 11b\n") }, 
    qr(\A\Q[1]\E Test 11a\n\Q[1]\E Test 11b\n\z), 
    'trace_line works (multiline) at level 2'
);


# Tests 12-14: trace_line errors

eval { $misc->trace_line(-1, q[ ]); };

like( $@, qr(invalid: tracelevel), 'trace_line prints tracelevel error');

eval { $misc->trace_line(1, q[]); };

like( $@ , qr(invalid: text), 'trace_line prints text error');

$misc->set_trace(5);
eval { $misc->set_trace(-1); };

like( $@ , qr(invalid: tracelevel), 'set_trace prints invalid tracelevel error');

