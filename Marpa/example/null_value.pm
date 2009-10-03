package Marpa::Example;

use 5.010;
use warnings;
use strict;

# The start rule
## no critic (Subroutines::RequireArgUnpacking)
sub rule0 { return $_[0] . ", but " . $_[1] }
## use critic
sub rule1 { return 'A is missing' }
sub rule2 { return "I'm sometimes null and sometimes not" }
sub rule3 { return 'B is missing' }
sub rule4 { return 'C is missing' }
sub rule5 { return 'C matches Y' }
sub rule6 { return 'Zorro was here' }

1;
