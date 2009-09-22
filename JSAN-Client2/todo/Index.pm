package JSAN::Client2::Index;

use 5.008;
use strict;
use warnings;
use File::HomeDir 0.86 ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.20';
}	

use ORLite::Migrate 0.02 {
	create        => 1,
	user_revision => 1,
	file          => File::Spec->catdir(
		File::HomeDir->my_data,
		($^O eq 'MSWin32' ? 'Perl' : '.perl'),
		'JSAN-Client2',
	),
	timeline      => File::Spec->catdir(
		File::ShareDir::dist_dir('JSAN-Client2),
		'migrate',
	),
};

1;
