#!perl

use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 2;
use Fatal qw( open close );
use Carp;

# Module specific stuff here -- setup code
use Scalar::Util qw(weaken isweak);

BEGIN { use_ok('Test::Weaken') };

package Module::Test_me1; sub new { bless [], (shift); }
package Module::Test_me2; sub new { bless [], (shift); }

package main;

# slurp in the code
my $filename = $INC{'Test/Weaken.pm'};
open my $code_fh, '<', $filename;
my $code = do { local($RS) = undef; <$code_fh> };
close $code_fh;

# remove stuff before and after the SYNOPSIS
$code =~ s/.*^=head1\s*SYNOPSIS\s*$//xms;
$code =~ s/^=head1.*\z//xms;

# remove POD text
$code =~ s/^\S[^\n]*$//xmsg;

# compute line count -- don't include whitespace lines
$code =~ s/^\s*$//xmsg;
my @lines = split /\n/xms, $code;
my $line_count = @lines;

# check for absence of code
if ($code =~ /\A\s*\z/xms) {
    fail('No code in synopsis');
}

# Try the code and see what happens
## no critic (BuiltinFunctions::ProhibitStringyEval)
elsif ( eval $code ) {
## use critic
    pass("Synopsis has $line_count lines of good code");

}
else {
    fail("Synopsis code failed: $EVAL_ERROR");
}

