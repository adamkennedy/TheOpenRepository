
use strict;
use warnings;
use English;
use Test::More tests => 2;

# Module specific stuff here -- setup code
use Scalar::Util qw(weaken isweak);

BEGIN { use_ok('Test::Weaken') };

package Module::Test_me1; sub new { bless [], (shift); }
package Module::Test_me2; sub new { bless [], (shift); }

package main;

# slurp in the code
my $filename = $INC{"Test/Weaken.pm"};
unless (open(CODE, $filename)) {
    fail("Cannot open $filename");
    exit(1);
}
$RS = undef;
my $code = <CODE>;

# remove stuff before and after the SYNOPSIS
$code =~ s/.*^=head1\s*SYNOPSIS\s*$//xms;
$code =~ s/^=head1.*\z//xms;

# remove POD text
$code =~ s/^\S[^\n]*$//xmsg;

# compute line count -- don't include whitespace lines
$code =~ s/^\s*$//xmsg;
my @lines = split(/\n/, $code);
my $line_count = @lines;

# check for absence of code
if ($code =~ /\A\s*\z/xms) {
    fail("No code in synopsis");
    exit(1);
}

# Try the code and see what happens
eval $code;

# Report the results
if ($@) {
    fail("Synopsis code failed: $@");
} else {
    pass("Synopsis has $line_count lines of good code");
}

