#!perl

# The first, basic test case for the ignore option
# was supplied by Kevin Ryde.

use strict;
use warnings;

use Test::More tests => 24;
use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw(open close);

use lib 't/lib';
use Test::Weaken::Test;

sub divert_stderr {
    my $stderr = q{};
    open my $save_stderr, '>&STDERR';
    close STDERR;
    open STDERR, '>', \$stderr;
    return sub {
        open STDERR, '>&', $save_stderr;
        close $save_stderr;
        return $stderr;
    };
}

package MyGlobal;

my %cache;

sub new {
    my ( $class, $name ) = @_;
    return (
        $cache{$name} ||= bless {
            name  => $name,
            array => ["something for $name"],
        },
        $class
    );
}

package MyObject;

sub new {
    my ($class) = @_;
    return bless {
        one => MyGlobal->new('foo'),
        two => MyGlobal->new('bar'),
    }, $class;
}

package MyCycle;

sub new {
    my ($class) = @_;
    my $weak;
    my $strong = \$weak;
    my $self   = \$strong;
    Scalar::Util::weaken( $weak = \$self );
    return bless [ \$self ], $class;
}

package DeepObject;

sub new {
    my ($class) = @_;
    return bless { one => { two => { three => 4 } } }, $class;
}

package main;

use Scalar::Util;
use Data::Dumper;

BEGIN {
    use_ok('Test::Weaken');
}

use lib 't/lib';
use Test::Weaken::Test;

## use Marpa::Test::Display ignore snippet

sub ignore_my_global {
    my ($thing) = @_;
    return ( Scalar::Util::blessed($thing) && $thing->isa('MyGlobal') );
}

my $test = Test::Weaken::leaks(
    {   constructor => sub { MyObject->new },
        ignore      => \&ignore_my_global,
    }
);

## no Marpa::Test::Display

if ( not $test ) {
    pass('good ignore');
}
else {
    Test::Weaken::Test::is( $test->unfreed_proberefs, q{}, 'good ignore' );
}

$test = Test::Weaken::leaks(
    {   constructor => sub { MyObject->new },
        ignore      => sub { return; }
    }
);
Test::Weaken::Test::is( Dumper( $test->unfreed_proberefs ),
    <<'EOS', 'no-op ignore' );
$VAR1 = [
          bless( {
                   'array' => [
                                'something for foo'
                              ],
                   'name' => 'foo'
                 }, 'MyGlobal' ),
          bless( {
                   'array' => [
                                'something for bar'
                              ],
                   'name' => 'bar'
                 }, 'MyGlobal' ),
          $VAR1->[0]{'array'},
          $VAR1->[1]{'array'}
        ];
EOS

## use Marpa::Test::Display check_ignore 1 arg snippet
$test = Test::Weaken::leaks(
    {   constructor => sub { MyObject->new },
        ignore => Test::Weaken::check_ignore( \&ignore_my_global ),
    }
);
## no Marpa::Test::Display

if ( not $test ) {
    pass('wrappered good ignore');
}
else {
    Test::Weaken::Test::is( $test->unfreed_proberefs, q{},
        'wrappered good ignore' );
}

sub overwriting_ignore {
    my ($probe_ref) = @_;
    ${$probe_ref} = 'XXX';
    return 0;
}

my $restore     = divert_stderr();
my $eval_return = eval {
    Test::Weaken::leaks(
        {   constructor => sub { MyObject->new },
            ignore => Test::Weaken::check_ignore( \&overwriting_ignore ),
        }
    );
    1;
};
my $stderr = &{$restore};

my $eval_result = 'proberef overwrite not caught';
if ( not $eval_return ) {
    $eval_result = $EVAL_ERROR;
}

$eval_result =~ s{
    [ ] at [ ] (\S+) [ ] line [ ] \d+ $
}{ at <FILE> line <LINE_NUMBER>}gxms;

Test::Weaken::Test::is(
    ( $stderr . $eval_result ),
    <<'EOS',
Probe referent changed by ignore call
Terminating ignore callbacks after finding 1 error(s) at <FILE> line <LINE_NUMBER>
EOS
    'wrappered overwriting ignore'
);

## no critic (Subroutines::RequireArgUnpacking)
# Trigger warnings, while replacing everything with its equivalent
sub buggy_ignore {
    $_[0] = \${ $_[0] } if Scalar::Util::reftype $_[0] eq 'REF';
    if ( Scalar::Util::reftype $_[0] eq 'ARRAY' ) {
        my @temp = @{ $_[0] };
        $_[0] = \@temp;
    }
    if ( Scalar::Util::reftype $_[0] eq 'HASH' ) {
        my %temp = %{ $_[0] };
        $_[0] = \%temp;
    }
    if ( Scalar::Util::reftype $_[0] eq 'REF' ) {
        my $temp = ${ $_[0] };
        $_[0] = \$temp;
    }
    return 0;
}
## use critic

my %counted_error_expected = (
    0 => <<'EOS',
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
EOS
    1 => <<'EOS',
Probe referent changed by ignore call
Terminating ignore callbacks after finding 1 error(s) at <FILE> line <LINE_NUMBER>
EOS
    2 => <<'EOS',
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
Probe referent changed by ignore call
Terminating ignore callbacks after finding 2 error(s) at <FILE> line <LINE_NUMBER>
EOS
    3 => <<'EOS',
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
Probe referent changed by ignore call
Terminating ignore callbacks after finding 3 error(s) at <FILE> line <LINE_NUMBER>
EOS
    4 => <<'EOS',
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
EOS
);

sub counted_errors {
    my ($error_count) = @_;

    $restore     = divert_stderr();
    $eval_return = eval {

## use Marpa::Test::Display check_ignore snippet

        Test::Weaken::leaks(
            {   constructor => sub { MyObject->new },
                ignore      => Test::Weaken::check_ignore(
                    \&buggy_ignore, $error_count
                ),
            }
        );

## no Marpa::Test::Display

    };
    $stderr = &{$restore};

    # the exact addresses will vary, so just X them out
    $stderr =~ s/0x[0-9a-fA-F]*/0xXXXXXXX/gxms;

    $stderr .= $EVAL_ERROR if not $eval_return;

    $stderr =~ s{
        [ ] at [ ] (\S+) [ ] line [ ] \d+ $
    }{ at <FILE> line <LINE_NUMBER>}gxms;

    Test::Weaken::Test::is(
        $stderr,
        $counted_error_expected{$error_count},
        "wrappered overwriting ignore, max_errors=$error_count"
    );

    return 1;
}

counted_errors(0);
counted_errors(1);
counted_errors(2);
counted_errors(3);
counted_errors(4);

sub noop_ignore { return 0; }

$test = Test::Weaken::leaks(
    {   constructor => sub { MyCycle->new },
        ignore      => \&noop_ignore,
    }
);
if ( not $test ) {
    pass('cycle w/ no-op ignore');
}
else {
    Test::Weaken::Test::is( $test->unfreed_proberefs, q{},
        'cycle w/ no-op ignore' );
}

## no critic (Subroutines::RequireArgUnpacking)
sub copying_ignore {
    if ( Scalar::Util::reftype $_[0] eq 'REF' ) {
        my $temp = ${ $_[0] };
        ${ $_[0] } = $temp;
    }
    return 0;
}
## use critic

$test = Test::Weaken::leaks(
    {   constructor => sub { MyCycle->new },
        ignore      => \&copying_ignore,
    }
);
if ( not $test ) {
    pass('cycle w/ copying ignore');
}
else {
    my $unfreed = $test->unfreed_proberefs;
    Test::Weaken::Test::is(
        Data::Dumper->Dump( [$unfreed], [qw(unfreed)] ),
        <<'EOS',
$unfreed = [
             \\\$unfreed->[0],
             ${$unfreed->[0]},
             ${${$unfreed->[0]}}
           ];
EOS
        'cycle w/ copying ignore'
    );
}

$restore     = divert_stderr();
$eval_return = eval {

    $test = Test::Weaken::leaks(
        {   constructor => sub { MyCycle->new },
            ignore => Test::Weaken::check_ignore( \&copying_ignore, 2 ),
        }
    );
};
$stderr = &{$restore};

if ( not $test ) {
    pass('cycle w/ copying & error callback');
}
else {
    my $unfreed = $test->unfreed_proberefs;
    Test::Weaken::Test::is(
        Data::Dumper->Dump( [$unfreed], [qw(unfreed)] ),
        <<'EOS',
$unfreed = [
             \\\$unfreed->[0],
             ${$unfreed->[0]},
             ${${$unfreed->[0]}}
           ];
EOS
        'unfreed refs for cycle w/ copying'
    );
}

# the exact addresses will vary, so just X them out
$stderr =~ s/0x[0-9a-fA-F]*/0xXXXXXXX/gxms;
$stderr .= $EVAL_ERROR if not $eval_return;
$stderr =~ s{
    [ ] at [ ] (\S+) [ ] line [ ] \d+ $
}{ at <FILE> line <LINE_NUMBER>}gxms;

Test::Weaken::Test::is(
    $stderr,
    <<'EOS',
Probe referent strengthened by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
EOS
    'stderr for cycle w/ copying'
);

sub cause_deep_problem {
    my ($proberef) = @_;
    if (    ref $proberef eq 'REF'
        and Scalar::Util::reftype ${$proberef} eq 'HASH'
        and exists ${$proberef}->{one} )
    {
        ${$proberef}->{one}->{bad} = 42;
    }
    return 0;
}

my %counted_compare_depth_expected = (
    0 => <<'EOS',
$proberef_before_callback = \bless( {
                                       'one' => {
                                                  'two' => {
                                                             'three' => 4
                                                           }
                                                }
                                     }, 'DeepObject' );
$proberef_after_callback = \bless( {
                                      'one' => {
                                                 'bad' => 42,
                                                 'two' => {
                                                            'three' => 4
                                                          }
                                               }
                                    }, 'DeepObject' );
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
EOS
    1 => <<'EOS',
EOS
    2 => <<'EOS',
EOS
    3 => <<'EOS',
$proberef_before_callback = \bless( {
                                       'one' => {
                                                  'two' => 'HASH(0xXXXXXXX)'
                                                }
                                     }, 'DeepObject' );
$proberef_after_callback = \bless( {
                                      'one' => {
                                                 'bad' => 42,
                                                 'two' => 'HASH(0xXXXXXXX)'
                                               }
                                    }, 'DeepObject' );
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
EOS
    4 => <<'EOS',
$proberef_before_callback = \bless( {
                                       'one' => {
                                                  'two' => {
                                                             'three' => 4
                                                           }
                                                }
                                     }, 'DeepObject' );
$proberef_after_callback = \bless( {
                                      'one' => {
                                                 'bad' => 42,
                                                 'two' => {
                                                            'three' => 4
                                                          }
                                               }
                                    }, 'DeepObject' );
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
EOS
);

sub counted_compare_depth {
    my ($compare_depth) = @_;

    $restore     = divert_stderr();
    $eval_return = eval {
        Test::Weaken::leaks(
            {   constructor => sub { DeepObject->new },
                ignore      => Test::Weaken::check_ignore(
                    \&cause_deep_problem, 99,
                    $compare_depth,       $compare_depth
                ),
            }
        );
    };
    $stderr = &{$restore};

    # the exact addresses will vary, so just X them out
    $stderr =~ s/0x[0-9a-fA-F]*/0xXXXXXXX/gxms;

    $stderr .= $EVAL_ERROR if not $eval_return;

    $stderr =~ s{
        [ ] at [ ] (\S+) [ ] line [ ] \d+ $
    }{ at <FILE> line <LINE_NUMBER>}gxms;

    Test::Weaken::Test::is(
        $stderr,
        $counted_compare_depth_expected{$compare_depth},
        "deep problem, compare depth=$compare_depth"
    );

    return 1;
}

counted_compare_depth(0);
counted_compare_depth(1);
counted_compare_depth(2);
counted_compare_depth(3);
counted_compare_depth(4);

my %counted_reporting_depth_expected = (
    0 => <<'EOS',
$proberef_before_callback = \bless( {
                                       'one' => {
                                                  'two' => {
                                                             'three' => 4
                                                           }
                                                }
                                     }, 'DeepObject' );
$proberef_after_callback = \bless( {
                                      'one' => {
                                                 'bad' => 42,
                                                 'two' => {
                                                            'three' => 4
                                                          }
                                               }
                                    }, 'DeepObject' );
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
EOS
    1 => <<'EOS',
$proberef_before_callback = \'DeepObject=HASH(0xXXXXXXX)';
$proberef_after_callback = \'DeepObject=HASH(0xXXXXXXX)';
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
EOS
    2 => <<'EOS',
$proberef_before_callback = \bless( {
                                       'one' => 'HASH(0xXXXXXXX)'
                                     }, 'DeepObject' );
$proberef_after_callback = \bless( {
                                      'one' => 'HASH(0xXXXXXXX)'
                                    }, 'DeepObject' );
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
EOS
    3 => <<'EOS',
$proberef_before_callback = \bless( {
                                       'one' => {
                                                  'two' => 'HASH(0xXXXXXXX)'
                                                }
                                     }, 'DeepObject' );
$proberef_after_callback = \bless( {
                                      'one' => {
                                                 'bad' => 42,
                                                 'two' => 'HASH(0xXXXXXXX)'
                                               }
                                    }, 'DeepObject' );
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
EOS
    4 => <<'EOS',
$proberef_before_callback = \bless( {
                                       'one' => {
                                                  'two' => {
                                                             'three' => 4
                                                           }
                                                }
                                     }, 'DeepObject' );
$proberef_after_callback = \bless( {
                                      'one' => {
                                                 'bad' => 42,
                                                 'two' => {
                                                            'three' => 4
                                                          }
                                               }
                                    }, 'DeepObject' );
Probe referent changed by ignore call
Above errors reported at <FILE> line <LINE_NUMBER>
EOS
);

sub counted_reporting_depth {
    my ($reporting_depth) = @_;

    $restore     = divert_stderr();
    $eval_return = eval {
## use Marpa::Test::Display check_ignore 4 arg snippet
        $test = Test::Weaken::leaks(
            {   constructor => sub { DeepObject->new },
                ignore      => Test::Weaken::check_ignore(
                    \&cause_deep_problem, 99, 0, $reporting_depth
                ),
            }
        );
## no Marpa::Test::Display
    };
    $stderr = &{$restore};

    # the exact addresses will vary, so just X them out
    $stderr =~ s/0x[0-9a-fA-F]*/0xXXXXXXX/gxms;

    $stderr .= $EVAL_ERROR if not $eval_return;

    $stderr =~ s{
        [ ] at [ ] (\S+) [ ] line [ ] \d+ $
    }{ at <FILE> line <LINE_NUMBER>}gxms;

    Test::Weaken::Test::is(
        $stderr,
        $counted_reporting_depth_expected{$reporting_depth},
        "deep problem, reporting depth=$reporting_depth"
    );

    return 1;
}

counted_reporting_depth(0);
counted_reporting_depth(1);
counted_reporting_depth(2);
counted_reporting_depth(3);
counted_reporting_depth(4);

