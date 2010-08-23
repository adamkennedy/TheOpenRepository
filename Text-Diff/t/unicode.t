#!/usr/bin/perl

use strict;

BEGIN
{
    $ENV{'DIFF_OUTPUT_UNICODE'} = 1;
}

use Test::More;
use Text::Diff;

eval "use Encode;";

if ($@)
{
    plan skip_all => "No utf8.";
}
else
{
    plan tests => 3;
}

sub u
{
    return decode("utf-8", shift);
}

sub ind
{
    my $s = u(shift(@_));
    return index( diff( \(u("שלום"), u("שלוש")), { STYLE => "Table" } ), $s );
}

# TEST
ok (
    (ind("ש") >= 0),
    "Output in unicode."
);

{
    local $Text::Diff::Config::Output_Unicode = 0;
    # To settle use warnings;
    $Text::Diff::Config::Output_Unicode = 0+0;

    # TEST
    ok (
        (ind ("\\x{05e9}" ) >= 0),
        "Output not in unicode."
    );
    
    # TEST
    ok (
        (ind( "ש" ) < 0 ),
        "Output not in unicode - no unicode char found."
    );
}

