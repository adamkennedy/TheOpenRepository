package _Aspect::tests::Advice::Foo;

use strict;
use warnings;
use Carp;

sub new { bless {}, shift }
sub foo { 'foo'           }
sub bar { shift->foo      }
sub inc { $_[1] + 1       }

sub main::advice_tests_func_no_proto       { shift }

sub main::advice_tests_func_with_proto ($) { shift }

1;
