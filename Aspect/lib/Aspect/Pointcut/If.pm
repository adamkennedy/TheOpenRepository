package Aspect::Pointcut::If;

use strict;
use warnings;
use Aspect::Pointcut ();

our $VERSION = '0.38';
our @ISA     = 'Aspect::Pointcut';





######################################################################
# Weaving Methods

# We match everything at curry-time
sub match_define {
	return 1;
}

# The condition pointcut contains no state and doesn't need to be curried.
# Simply return it as-is and reuse it everywhere.
sub curry_run {
	return $_[0];
}





######################################################################
# Runtime Methods

# Match only when code returns boolean true
sub match_run {
	return !! $_[0]->[0]->();
}

1;
