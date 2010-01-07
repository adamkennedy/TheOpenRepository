package Aspect::Library::Profiler::Cleanup;

use 5.006;
use strict;
use warnings;
use Benchmark::Timer ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.32';
	@ISA     = 'Benchmark::Timer';
}

sub DESTROY {
	print scalar $_[0]->reports;
}

1;
