package POE::Thing::Registry;

use 5.008005;
use strict;
use Carp         qw{ croak  };
use Params::Util qw{ _CLASS };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Create Registry Stores

our %ALIAS_BASE  = ();
our %ALIAS_COUNT = ();

sub init_class {
	my $name  = _CLASS(shift);
	unless ( $name ) {
		croak("Did not provide a class to POE::Thing::Registry::init_class");
	}
	my $alias = @_ ? _CLASS(shift) : $name;
	unless ( $alias ) {
		croak("Did not provide a value alias base name");
	}

	$ALIAS_BASE{$class}  = $alias;
	$ALIAS_COUNT{$alias} = 0;

	return 1;
}

sub next_alias {
	my $base = $ALIAS_BASE{shift};
	unless ( $base ) {
		croak("Did not provide an existing class to POE::Thing::Registry::next_alias");
	}

	$base . '.' . ++$ALIAS_COUNT{$base};
}

1;
