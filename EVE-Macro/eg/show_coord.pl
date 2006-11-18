#!/usr/bin/perl

use strict;

use strict;
use FindBin    ();
use File::Spec ();
use lib File::Spec->catdir(
	$FindBin::Bin, File::Spec->updir, 'lib',
	);
use EVE::Macro::Object;





#####################################################################
# Main Script

my $eve = EVE::Macro::Object->new;

while ( 1 ) {
	my $coord = $eve->mouse_pos;
	print "Mouse at: $coord->[0],$coord->[1]\n";
	sleep(1);
}

exit(0);





#####################################################################
# Support Functions

use vars qw{$WINDOW};
BEGIN {
	$Win32::GuiTest::debug = 0;
	my @windows = Win32::GuiTest::FindWindowLike(0, '^EVE$');
	unless ( @windows == 1 ) {
		die "More than one eve window";
	}
	$WINDOW = $windows[0];
}

sub type ($) {
	Win32::GuiTest::SetForegroundWindow($WINDOW);
	Win32::GuiTest::SendKeys($_[0]);
}

sub mouse ($) {
	Win32::GuiTest::SetForegroundWindow($WINDOW);
	Win32::GuiTest::SendKeys($_[0]);
}

use vars qw{%PLACES};
BEGIN {
	%PLACES = (
		menu_1 => [ 10, 150 ],
		menu_2 => [ 10, 170 ],
		);
}

sub mouse_to {
	Win32::GuiTest::SetForegroundWindow($WINDOW);
	if ( _POSINT($_[0]) and _POSINT($_[1]) ) {
		Win32::GuiTest::MouseMoveAbsPix($_[0], $_[1]);
		return 1;
	}
	if ( _STRING($_[0]) ) {
		if ( $PLACES{$_[0]} ) {
			Win32::GuiTest::MouseMoveAbsPix( @{ $PLACES{$_[0]} } );
			return 1;
		}
	}
	die "Unknown place to move to";
}

sub left_click () {
	Win32::GuiTest::SendLButtonDown();
	Win32::GuiTest::SendLButtonUp();
}

use vars qw{$MENU_X $MENU_Y $MENU_Y_INTERVAL};
BEGIN {
	$MENU_X          = 20;
	$MENU_Y          = 120;
	$MENU_Y_INTERVAL = 27;
}

sub mouse_to_left_menu ($) {
	my $x = $MENU_X;
	my $y = $MENU_Y + $MENU_Y_INTERVAL * $_[0];
	mouse_to( $x, $y );
}

sub click_left_menu ($) {
	mouse_to_left_menu( $_[0] );
	left_click;
}

1;
