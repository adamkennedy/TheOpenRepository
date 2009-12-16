use warnings;
use 5.010;
use Parse::Marpa;
use Test::More tests => 1;
use Carp;
use Fatal qw(open close select);

my $eval_error = q{};
{
    local $@;
    eval {
        say ${
            Parse::Marpa::mdl(
                (   do { local $/ = undef; my $source = <DATA>; \$source; }
                ),
                \('2')
            )
            };
    };
    $eval_error = $@;
}
 
my $expected = <<'END_OF_EXPECTED';
Parse failed at line 1, earleme <<LINE_NUMBER>>

                 ^
 at t/rt_52724.t line 14
END_OF_EXPECTED

$eval_error =~ s/, \s+ earleme \s+ (\d+)$/, earleme <<LINE_NUMBER>>/xms;

Test::More::is($eval_error, $expected, 'RT 52724');

exit 0;

__DATA__
semantics are perl5.
version is 1.005_002.
start symbol is Expression.

Expression: /\d+/, /[+]/, /\d+/. q{$_[0] + $_[2]}.
