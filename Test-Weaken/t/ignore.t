#!perl

# The first, basic test case for the ignore option
# was supplied by Kevin Ryde.

use strict;
use warnings;

use Test::More tests => 5;
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

package main;

use Scalar::Util;
use Data::Dumper;

BEGIN {
    use_ok('Test::Weaken');
}

use lib 't/lib';
use Test::Weaken::Test;

sub good_ignore {
    my ($thing) = @_;
    return ( Scalar::Util::blessed($thing) && $thing->isa('MyGlobal') );
}

my $test = Test::Weaken::leaks(
    {   constructor => sub { MyObject->new },
        ignore      => \&good_ignore,
    }
);
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
        ignore => Test::Weaken::check_ignore( \&good_ignore ),
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
sub replacing_ignore {
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

sub error_callback {
    my ( $standard_message, $before_signature, $after_signature, $probe_ref )
        = @_;
    my $custom_message = "'$before_signature' -> '$after_signature'\n";
    print {*STDERR} $custom_message
        or croak("Cannot print STDERR: $ERRNO");
    return 1;
}

my $stderr = q{};
open my $save_stderr, '>&STDERR';
close STDERR;
open STDERR, '>', \$stderr;

Test::Weaken::leaks(
    {   constructor => sub { MyObject->new },
        ignore      => Test::Weaken::check_ignore(
            \&replacing_ignore, \&error_callback
        ),
    }
);

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
