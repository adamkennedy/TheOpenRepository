package POE::Thing::Registry;

use 5.008005;
use strict;
use Carp             qw{ croak   };
use Scalar::Util     qw{ refaddr };
use Params::Util     qw{ _CLASS  };
use Class::Inspector ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Create Registry Stores

our %ALIAS_BASE    = ();
our %ALIAS_COUNT   = ();
our %EVENTS        = ();
our %INLINE_STATES = ();

sub init_class {
	my $class  = _CLASS(shift);
	unless ( $class ) {
		croak("Did not provide a class to POE::Thing::Registry::init_class");
	}
	my $alias = @_ ? _CLASS(shift) : $class;
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

# Resolve the inline states for a class
sub inline_states {
	my $class  = _CLASS(shift);
	unless ( $class ) {
		croak("Did not provide a class to POE::Thing::Registry::inline_states");
	}

	# Generate if needed
	unless ( $INLINE_STATES{$class} ) {
		my %states = ();

		# Get our inheritance chain
		my $methods = Class::Inspector->methods( 'Foo', 'expanded' );
		foreach my $method ( @$methods ) {
			next unless $EVENTS{$class}->{refaddr $method->[3]};
			$states{$method->[2]} = $method->[3];
		}

		$INLINE_STATES{$class} = \%states;
	}

	$INLINE_STATES{$class}
}

1;
