#!/usr/bin/perl -w

# Test various miscellaneous configurationh functions

use strict;
BEGIN {
	$| = 1;
}

use Test::More tests => 28;
use Kepher;





#####################################################################
# Kepher::Config::color

sub is_color {
	my ($it, $r, $g, $b, $name) = @_;
	isa_ok( $it, 'Wx::Colour' );
	is( $it->Red,   $r, "$name: ->Red ok"   );
	is( $it->Green, $g, "$name: ->Green ok" );
	is( $it->Blue,  $b, "$name: ->Blue ok"  );
}

SCOPE: {
	my $black1 = Kepher::Config::color('000000');
	my $white1 = Kepher::Config::color('FFFFFF');
	my $black2 = Kepher::Config::color('0,0,0');
	my $white2 = Kepher::Config::color('255,255,255');
	is_color( $black1, 0, 0, 0, 'hex black' );
	is_color( $black2, 0, 0, 0, 'dec black' );
	is_color( $white1, 255, 255, 255, 'hex white' );
	is_color( $white2, 255, 255, 255, 'dec white' );

	# Check errors
	eval {
		Kepher::Config::color();
	};
	like( $@, qr/Color string is not defined/, 'Caught undef error' );
	eval {
		Kepher::Config::color('black');
	};
	like( $@, qr/Unknown color string/, 'Caught bad-string error' );
}





#####################################################################
# Kepher::Config::icon_bitmap

sub is_icon {
	my $it = shift;
	isa_ok( $it, 'Wx::Bitmap' );
}

SCOPE: {
	# Set the default icon path for testing purposes
	local $Kepher::config{app}->{iconset_path} = 'icon/set/jenne';

	my @known_good = qw{
		edit_delete
		find_previous
		find_next
		goto_last_edit
		find_start
		};
	foreach my $name ( @known_good ) {
		# Create using the raw name
		my $icon1 = Kepher::Config::icon_bitmap( $name );
		is_icon( $icon1 );

		# Create using the .xpm name
		my $icon2 = Kepher::Config::icon_bitmap( $name . '.xpm' );
		is_icon( $icon2 );
	}
}

exit(0);
