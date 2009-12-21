package Aspect::Advice::After;

use strict;
use warnings;
use Aspect::Advice ();

our $VERSION = '0.22';
our @ISA     = 'Aspect::Advice';

sub new {
	my $class = shift;
	return bless { @_ }, $class;
}

sub type { 'after' }

1;
