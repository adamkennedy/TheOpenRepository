#!perl

# The first, basic test case for the ignore option
# was supplied by Kevin Ryde.

use strict;
use warnings;

use Test::More tests => 10;
use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw(open close);

use lib 't/lib';
use Test::Weaken::Test;

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

$test = Test::Weaken::leaks(
    {   constructor => sub { MyObject->new },
        ignore => Test::Weaken::check_ignore( \&ignore_my_global ),
    }
);
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

my $eval_return = eval {
    Test::Weaken::leaks(
        {   constructor => sub { MyObject->new },
            ignore => Test::Weaken::check_ignore( \&overwriting_ignore ),
        }
    );
    1;
};
my $eval_result = 'proberef overwrite not caught';
if ( not $eval_return ) {
    $eval_result = $EVAL_ERROR;
    $eval_result =~ s/[^']*\z//xms;
    $eval_result =~ s/0x[0-9a-fA-F]+/0xXXXXXXX/xmsg;
}

Test::Weaken::Test::is(
    $eval_result,
    q{Problem in ignore callback: arg was changed from 'strong REF at 0xXXXXXXX' to 'SCALAR at 0xXXXXXXX'},
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

## use Marpa::Test::Display error callback snippet

{
    my $error_callback_count = 0;
    my $max_errors           = 100;

    sub error_callback {
        my ($standard_message, $before_signature,
            $after_signature,  $probe_ref
        ) = @_;
        $error_callback_count++;
        my $custom_message = "'$before_signature' -> '$after_signature'\n";
        print {*STDERR} $custom_message
            or croak("Cannot print STDERR: $ERRNO");
        if ( $error_callback_count > $max_errors ) {
            croak("Terminating after $max_errors errors");
        }
        return 1;
    }
}

## no Marpa::Test::Display

my $stderr = q{};
open my $save_stderr, '>&STDERR';
close STDERR;
open STDERR, '>', \$stderr;

## use Marpa::Test::Display check_ignore snippet

Test::Weaken::leaks(
    {   constructor => sub { MyObject->new },
        ignore =>
            Test::Weaken::check_ignore( \&buggy_ignore, \&error_callback ),
    }
);

## no Marpa::Test::Display

open STDERR, '>&', $save_stderr;
close $save_stderr;

# the exact addresses will vary, so just X them out
$stderr =~ s/0x[0-9a-fA-F]*/0xXXXXXXX/gxms;

Test::Weaken::Test::is( $stderr,
    <<'EOS', 'wrappered overwriting ignore w/ error callback' );
'strong REF at 0xXXXXXXX' -> 'strong REF at 0xXXXXXXX'
'MyObject at 0xXXXXXXX' -> 'HASH at 0xXXXXXXX'
'strong REF at 0xXXXXXXX' -> 'strong REF at 0xXXXXXXX'
'strong REF at 0xXXXXXXX' -> 'strong REF at 0xXXXXXXX'
'MyGlobal at 0xXXXXXXX' -> 'HASH at 0xXXXXXXX'
'MyGlobal at 0xXXXXXXX' -> 'HASH at 0xXXXXXXX'
'strong REF at 0xXXXXXXX' -> 'strong REF at 0xXXXXXXX'
'ARRAY at 0xXXXXXXX' -> 'ARRAY at 0xXXXXXXX'
'strong REF at 0xXXXXXXX' -> 'strong REF at 0xXXXXXXX'
'ARRAY at 0xXXXXXXX' -> 'ARRAY at 0xXXXXXXX'
EOS

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
    Test::Weaken::Test::is(
        Data::Dumper->Dump( [ $test->unfreed_proberefs ], [qw(unfreed)] ),
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

$stderr = q{};
open $save_stderr, '>&STDERR';
close STDERR;
open STDERR, '>', \$stderr;

$test = Test::Weaken::leaks(
    {   constructor => sub { MyCycle->new },
        ignore =>
            Test::Weaken::check_ignore( \&copying_ignore, \&error_callback ),
    }
);
if ( not $test ) {
    pass('cycle w/ copying & error callback');
}
else {
    Test::Weaken::Test::is(
        Data::Dumper->Dump( [ $test->unfreed_proberefs ], [qw(unfreed)] ),
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
Test::Weaken::Test::is(
    $stderr,
    qq{'weak REF at 0xXXXXXXX' -> 'strong REF at 0xXXXXXXX'\n},
    'stderr for cycle w/ copying'
);

open STDERR, '>&', $save_stderr;
close $save_stderr;
