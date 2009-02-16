package Perl::Metrics2;

use 5.008005;
use strict;

our $VERSION = '0.01';

use constant ORLITE_FILE => File::Spec->catfile(
	File::HomeDir->my_data,
	($^O eq 'MSWin32' ? 'Perl' : '.perl'),
	'Perl-Metrics2',
	'Perl-Metrics2.sqlite',
);

use constant ORLITE_TIMELINE => File::Spec->catdir(
	File::ShareDir::dist_dir('Perl-Metrics2'),
	'timeline',
);

use ORLite 1.20 ();
use ORLite::Migrate 