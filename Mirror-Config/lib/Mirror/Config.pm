package Mirror::Config;

use 5.005;
use base 'YAML::Tiny';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub name {
	$_[0]->{name};
}

1;
