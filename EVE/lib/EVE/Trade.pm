package EVE::Trade;

use 5.008;
use strict;
use warnings;
use File::Spec      0.80 ();
use File::HomeDir   0.93 ();
use File::ShareDir  1.00 ();
use ORLite          1.48 ();
use ORLite::Migrate 1.07 {
	create        => 1,
	user_revision => 2,
	file          => File::Spec->rel2abs(
		File::Spec->catfile(
			File::HomeDir->my_data,
			'Perl', 'EVE', 'EVE-Trade.sqlite',
		),
	),
	timeline      => File::Spec->catdir(
		File::ShareDir::dist_dir('EVE'),
		'timeline',
	),
}; #, '-DEBUG';

# Load overlay classes
use EVE::Trade::Market  ();
use EVE::Trade::MyOrder ();

our $VERSION = '0.01';

1;
