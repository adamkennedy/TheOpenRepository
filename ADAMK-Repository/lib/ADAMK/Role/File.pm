package ADAMK::Role::File;

# Provides methods for objects that represent filesystem locations

use 5.008;
use strict;
use warnings;
use File::Spec ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.09';
}

use Class::XSAccessor
	getters => {
		path => 'path',
	};

sub directory {
	$_[0]->path;
}

sub dir {
	File::Spec->catdir( shift->directory, @_ );
}

sub file {
	File::Spec->catfile( shift->directory, @_ );
}

# A simple _slurp implementation
sub _slurp {
	my $file = $_[1];
	local $/;
	local *FILE;
	open( FILE, '<', $file ) or die("open($file): $!");
	my $source = <FILE>;
	close( FILE ) or die("close($file): $!");
	return $source;
}

1;
