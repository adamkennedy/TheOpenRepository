package Module::Plan::P5Z;

use 5.005;
use strict;
use File::pushd  ();
use Archive::Tar ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}





#####################################################################
# Constructor

sub read {
	my $class = shift;
	my $self  = bless { @_ }, $self;

	# Apply defaults
	$self->{tempd} ||= File::pushd::tempd();
	
}

sub tempd {
	$_[0]->{tempd};
}

1;
