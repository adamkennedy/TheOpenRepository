use strict;
use warnings;

use Test::More tests => 1;
use Thread::SharedVector;
pass();

my $sv = Thread::SharedVector->new("double");

