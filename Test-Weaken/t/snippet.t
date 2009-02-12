#!perl

use strict;
use warnings;
use Test::More tests => 4;
use Fatal qw(open close);

use lib 't/lib';
use Test::Weaken::Test;

BEGIN { use_ok('Test::Weaken') }

use Test::Weaken qw(leaks);
use Data::Dumper;
use Math::BigInt;
use Math::BigFloat;
use Carp;
use English qw( -no_match_vars );

package My_Object;

sub new {
    my $obj1 = new Math::BigInt('42');
    my $obj2 = new Math::BigFloat('7.11');
    return [ $obj1, $obj2 ];
}

package Bad_Object;

sub new {
    my $array = [ 42, 711 ];
    push @{$array}, $array;
    return $array;
}

package main;

sub useless_destructor { return 'I am useless' }

my $test_output;

$test_output = do {

    open my $save_stdout, '>&STDOUT';
    close STDOUT;
    my $code_output = q{};
    open STDOUT, q{>}, \$code_output;

    ## use Marpa::Test::Display leaks snippet

    my $test = Test::Weaken::leaks(
        {   constructor => sub { new Bad_Object },
            destructor  => \&useless_destructor,
        }
    );
    if ($test) {
        print "There are leaks\n" or croak("Cannot print to STDOUT: $ERRNO");
    }

    ## no Marpa::Test::Display

    open STDOUT, q{>&}, $save_stdout;
    close $save_stdout;
    $code_output;
};

Test::Weaken::Test::is( $test_output, <<'EOS', 'leaks snippet' );
There are leaks
EOS

$test_output = do {

    open my $save_stdout, '>&STDOUT';
    close STDOUT;
    my $code_output = q{!!!};
    open STDOUT, q{>}, \$code_output;

## use Marpa::Test::Display unfreed_proberefs snippet

    my $test = Test::Weaken::leaks( sub { new Bad_Object } );
    if ($test) {
        my $unfreed_proberefs = $test->unfreed_proberefs();
        my $unfreed_count     = @{$unfreed_proberefs};
        printf "%d of %d references were not freed\n",
            $test->unfreed_count(), $test->probe_count()
            or croak("Cannot print to STDOUT: $ERRNO");
        print "These are the probe references to the unfreed objects:\n"
            or croak("Cannot print to STDOUT: $ERRNO");
        for my $proberef ( @{$unfreed_proberefs} ) {
            print Data::Dumper->Dump( [$proberef], ['unfreed'] )
                or croak("Cannot print to STDOUT: $ERRNO");
        }
    }

## no Marpa::Test::Display

    open STDOUT, q{>&}, $save_stdout;
    close $save_stdout;
    $code_output;
};

Test::Weaken::Test::is( $test_output, <<'EOS', 'unfreed_proberefs snippet' );
1 of 2 references were not freed
These are the probe references to the unfreed objects:
$unfreed = [
             42,
             711,
             $unfreed
           ];
EOS

$test_output = do {

    open my $save_stdout, '>&STDOUT';
    close STDOUT;
    my $code_output;
    open STDOUT, q{>}, \$code_output;

    no warnings 'redefine';

    sub constructor {
        my $obj1 = new Math::BigInt('42');
        my $obj2 = new Math::BigFloat('7.11');
        return [ $obj1, $obj2 ];
    }

    use warnings;

## use Marpa::Test::Display new snippet

    my $test = new Test::Weaken( sub { new My_Object } );
    printf "There are %s\n", ( $test->test() ? 'leaks' : 'no leaks' )
        or croak("Cannot print to STDOUT: $ERRNO");

## no Marpa::Test::Display

    open STDOUT, q{>&}, $save_stdout;
    close $save_stdout;
    $code_output;

};

Test::Weaken::Test::is( $test_output, <<'EOS', 'new snippet' );
There are no leaks
EOS

# sub Test::Weaken::test {
# sub Test::Weaken::unfreed_count {
# sub Test::Weaken::probe_count {
# sub Test::Weaken::weak_probe_count {
# sub Test::Weaken::strong_probe_count {
