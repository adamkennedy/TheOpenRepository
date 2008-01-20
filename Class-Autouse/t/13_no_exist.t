#!/usr/bin/env perl -w

# after using Class::Autouse, make sure non-existent class/method
# calls fail

use strict;

use Test::More;

plan tests => 2;

use Class::Autouse;

eval { Foo->bar; };
like( $@, qr/locate object method \"bar\" via package \"Foo\"/ );

eval qq{ package Foo; };

eval { Foo->bar; };
like( $@, qr/locate object method \"bar\" via package \"Foo\"/ );

