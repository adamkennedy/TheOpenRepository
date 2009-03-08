#!perl

use strict;
use warnings;
use Test::More tests => 9;
use Fatal qw(open close);

use lib 't/lib';
use Test::Weaken::Test;

BEGIN { use_ok('Test::Weaken') }

use Carp;

package My_Object;

use Math::BigInt;
use Math::BigFloat;

sub new {
    my $obj1 = new Math::BigInt('42');
    my $obj2 = new Math::BigFloat('7.11');
    return [ $obj1, $obj2 ];
}

package Buggy_Object;
use Scalar::Util qw(weaken);

sub new {
    my $array = [ 42, 711 ];
    my $weak_ref;
    weaken( $weak_ref = $array );
    my $strong_ref = $array;
    push @{$array}, $array;
    push @{$array}, \$weak_ref;
    push @{$array}, \$strong_ref;
    return $array;
}

package main;

my $test_output;

package Test::Weaken::Test::Snippet::leaks;

sub destroy_buggy_object { }

$test_output = do {

    open my $save_stdout, '>&STDOUT';
    close STDOUT;
    my $code_output = q{};
    open STDOUT, q{>}, \$code_output;

    ## use Marpa::Test::Display leaks snippet

    use Test::Weaken;
    use English qw( -no_match_vars );

    my $tester = Test::Weaken::leaks(
        {   constructor => sub { new Buggy_Object },
            destructor  => \&destroy_buggy_object,
        }
    );
    if ($tester) {
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

package Test::Weaken::Test::Snippet::unfreed_proberefs;

$test_output = do {

    open my $save_stdout, '>&STDOUT';
    close STDOUT;
    my $code_output = q{!!!};
    open STDOUT, q{>}, \$code_output;

## use Marpa::Test::Display unfreed_proberefs snippet

    use Test::Weaken;
    use English qw( -no_match_vars );

    my $tester = Test::Weaken::leaks( sub { new Buggy_Object } );
    if ($tester) {
        my $unfreed_proberefs = $tester->unfreed_proberefs();
        my $unfreed_count     = @{$unfreed_proberefs};
        printf "%d of %d references were not freed\n",
            $tester->unfreed_count(), $tester->probe_count()
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
3 of 4 references were not freed
These are the probe references to the unfreed objects:
$unfreed = [
             42,
             711,
             $unfreed,
             \$unfreed,
             \$unfreed
           ];
$unfreed = \[
               42,
               711,
               ${$unfreed},
               \${$unfreed},
               $unfreed
             ];
$unfreed = \[
               42,
               711,
               ${$unfreed},
               $unfreed,
               \${$unfreed}
             ];
EOS

package Test::Weaken::Test::Snippet::unfreed_count;

$test_output = do {

    open my $save_stdout, '>&STDOUT';
    close STDOUT;
    my $code_output = q{};
    open STDOUT, q{>}, \$code_output;

    TEST: for my $i (0) {

## use Marpa::Test::Display unfreed_count snippet

        use Test::Weaken;
        use English qw( -no_match_vars );

        my $tester = Test::Weaken::leaks( sub { new Buggy_Object } );
        next TEST if not $tester;
        printf "%d objects were not freed\n", $tester->unfreed_count(),
            or croak("Cannot print to STDOUT: $ERRNO");

## no Marpa::Test::Display

    }    # TEST

    open STDOUT, q{>&}, $save_stdout;
    close $save_stdout;
    $code_output;
};

Test::Weaken::Test::is( $test_output, <<'EOS', 'unfreed_count snippet' );
3 objects were not freed
EOS

package Test::Weaken::Test::Snippet::probe_count;

sub destroy_buggy_object { }

$test_output = do {

    open my $save_stdout, '>&STDOUT';
    close STDOUT;
    my $code_output = q{};
    open STDOUT, q{>}, \$code_output;

    TEST: for my $i (0) {

        ## use Marpa::Test::Display probe_count snippet

        use Test::Weaken;
        use English qw( -no_match_vars );

        my $tester = Test::Weaken::leaks(
            {   constructor => sub { new Buggy_Object },
                destructor  => \&destroy_buggy_object,
            }
        );
        next TEST if not $tester;
        printf "%d of %d objects were not freed\n",
            $tester->unfreed_count(), $tester->probe_count()
            or croak("Cannot print to STDOUT: $ERRNO");

        ## no Marpa::Test::Display

    }    # TEST

    open STDOUT, q{>&}, $save_stdout;
    close $save_stdout;
    $code_output;
};

Test::Weaken::Test::is( $test_output, <<'EOS', 'probe_count snippet' );
3 of 4 objects were not freed
EOS

package Test::Weaken::Test::Snippet::weak_probe_count;

$test_output = do {
    open my $save_stdout, '>&STDOUT';
    close STDOUT;
    my $code_output = q{};
    open STDOUT, q{>}, \$code_output;

    TEST: for my $i (0) {
## use Marpa::Test::Display weak_probe_count snippet

        use Test::Weaken;
        use Scalar::Util qw(isweak);
        use English qw( -no_match_vars );

        my $tester = Test::Weaken::leaks( sub { new Buggy_Object }, );
        next TEST if not $tester;
        my $weak_unfreed_reference_count =
            scalar grep { ref $_ eq 'REF' and isweak( ${$_} ) }
            @{ $tester->unfreed_proberefs() };
        printf "%d of %d weak references were not freed\n",
            $weak_unfreed_reference_count, $tester->weak_probe_count(),
            or croak("Cannot print to STDOUT: $ERRNO");

## no Marpa::Test::Display
    }    # TEST

    open STDOUT, q{>&}, $save_stdout;
    close $save_stdout;
    $code_output;

};

Test::Weaken::Test::is( $test_output, <<'EOS', 'weak_probe_count snippet' );
1 of 1 weak references were not freed
EOS

package Test::Weaken::Test::Snippet::strong_probe_count;

sub destroy_buggy_object { }

$test_output = do {

    open my $save_stdout, '>&STDOUT';
    close STDOUT;
    my $code_output = q{};
    open STDOUT, q{>}, \$code_output;

    TEST: for my $i (0) {
## use Marpa::Test::Display strong_probe_count snippet

        use Test::Weaken;
        use English qw( -no_match_vars );
        use Scalar::Util qw(isweak);

        my $tester = Test::Weaken::leaks(
            {   constructor => sub { new Buggy_Object },
                destructor  => \&destroy_buggy_object,
            }
        );
        next TEST if not $tester;
        my $proberefs = $tester->unfreed_proberefs();
        my $strong_unfreed_object_count =
            grep { ref $_ ne 'REF' or not isweak( ${$_} ) } @{$proberefs};
        my $strong_unfreed_reference_count =
            grep { ref $_ eq 'REF' and not isweak( ${$_} ) } @{$proberefs};

        printf "%d of %d strong objects were not freed\n",
            $strong_unfreed_object_count, $tester->strong_probe_count(),
            or croak("Cannot print to STDOUT: $ERRNO");
        printf "%d of the unfreed strong objects were references\n",
            $strong_unfreed_reference_count
            or croak("Cannot print to STDOUT: $ERRNO");

## no Marpa::Test::Display
    }    # TEST

    open STDOUT, q{>&}, $save_stdout;
    close $save_stdout;
    $code_output;

};

Test::Weaken::Test::is( $test_output, <<'EOS', 'strong_probe_count snippet' );
2 of 3 strong objects were not freed
1 of the unfreed strong objects were references
EOS

package Test::Weaken::Test::Snippet::new;

$test_output = do {

    open my $save_stdout, '>&STDOUT';
    close STDOUT;
    my $code_output;
    open STDOUT, q{>}, \$code_output;

    no warnings 'redefine';

    use warnings;

## use Marpa::Test::Display new snippet

    use Test::Weaken;
    use English qw( -no_match_vars );

    my $tester        = new Test::Weaken( sub { new My_Object } );
    my $unfreed_count = $tester->test();
    my $proberefs     = $tester->unfreed_proberefs();
    printf "%d of %d objects freed\n", $unfreed_count, $tester->probe_count()
        or croak("Cannot print to STDOUT: $ERRNO");

## no Marpa::Test::Display

    open STDOUT, q{>&}, $save_stdout;
    close $save_stdout;
    $code_output;

};

Test::Weaken::Test::is( $test_output, <<'EOS', 'new snippet' );
0 of 7 objects freed
EOS

package Test::Weaken::Test::Snippet::test;

sub destroy_my_object { }

$test_output = do {

    open my $save_stdout, '>&STDOUT';
    close STDOUT;
    my $code_output;
    open STDOUT, q{>}, \$code_output;

    no warnings 'redefine';

    use warnings;

## use Marpa::Test::Display test snippet

    use Test::Weaken;
    use English qw( -no_match_vars );

    my $tester = new Test::Weaken(
        {   constructor => sub { new My_Object },
            destructor  => \&destroy_my_object,
        }
    );
    printf "There are %s\n", ( $tester->test() ? 'leaks' : 'no leaks' )
        or croak("Cannot print to STDOUT: $ERRNO");

## no Marpa::Test::Display

    open STDOUT, q{>&}, $save_stdout;
    close $save_stdout;
    $code_output;

};

Test::Weaken::Test::is( $test_output, <<'EOS', 'test snippet' );
There are no leaks
EOS

