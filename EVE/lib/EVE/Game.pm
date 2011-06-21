package EVE::Game;

use 5.008;
use strict;
use warnings;
use Carp                       ();
use File::Spec            0.80 ();
use File::HomeDir         0.93 ();
use File::ShareDir        1.00 ();
use Params::Util          1.00 ();
use Config::Tiny          2.02 ();
use File::Find::Rule      0.32 ();
use Time::HiRes         1.9718 ();
use Win32::GuiTest        1.58 ();
use Win32::Process        0.14 ('NORMAL_PRIORITY_CLASS');
use Win32::Process::List  0.09 ();
use Win32                 0.39 ();
use Imager                0.81 (); # Need Imager::Color->hsv
use Imager::Search        1.01 ();
use Imager::Search::Pattern    ();
use Imager::Search::Screenshot ();
use EVE::Config                ();
use EVE::MarketLogs            ();
use EVE::API                   ();
use EVE::TextPattern           ();
use EVE::DB                    ();

our $VERSION = '0.01';

BEGIN {
	$Win32::GuiTest::debug = 0;
}

use Object::Tiny::XS 1.01 qw{
	config
	config_file
	paranoid
	process
	window
	marketlogs
	patterns
};





#####################################################################
# Constants

# Screen locations
use constant {
	MOUSE_LOGIN_USERNAME          => [ 552, 687 ],
	MOUSE_LOGIN_CURRENT_CHARACTER => [ 170, 273 ],
	MOUSE_ESCAPE_RESET_TAB        => [ 522, 164 ],
	MOUSE_ESCAPE_RESET_WINDOWS    => [ 614, 209 ],
	MOUSE_NEOCOM_MARKET           => [ 18,  249 ],
	MOUSE_NEOCOM_PLACES           => [ 20,  175 ],
	MOUSE_MARKET_DETAILS_TAB      => [ 340, 113 ],
	MOUSE_MARKET_DATA_TAB         => [ 346, 227 ],
	MOUSE_MARKET_ORDERS_TAB       => [ 439, 114 ],
	MOUSE_MARKET_SEARCH_TAB       => [ 195, 200 ],
	MOUSE_MARKET_SEARCH_TEXT      => [ 121, 226 ],
	MOUSE_MARKET_EXPORT_ORDERS    => [ 328, 663 ],
	MOUSE_MARKET_EXPORT_MARKET    => [ 562, 670 ],
	MOUSE_PLACES_CLOSE            => [ 745, 190 ],
	MOUSE_PLACES_SEARCH_TEXT      => [ 433, 235 ],
	MOUSE_PLACES_RESULT_ONE       => [ 403, 388 ],
	MOUSE_PLACES_RESULT_CLOSE     => [ 513, 562 ],
	MOUSE_PLACES_SET_DESTINATION  => [ 450, 412 ],
	COLOR_SELECTED_APPROACH       => [ 758, 78  ],
	COLOR_SELECTED_WARP_TO        => [ 783, 78  ],
	COLOR_SELECTED_JUMP           => [ 808, 78  ],
};

# Market groups
use constant TRADE_GROUP_MINERALS => qw{ 18  476     };
use constant TRADE_GROUP_MOON     => qw{ 499 500 501 };





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Find and load the config file if it exists
	unless ( $self->config ) {
		# Are we looking for a specific config file
		my $file = $self->config_file || 'EVE.conf';
		unless ( File::Spec->file_name_is_absolute($file) ) {
			$file = File::Spec->catfile(
				File::HomeDir->my_documents,
				$file
				);
		}
		if ( -f $file ) {
			# Load the config file
			$self->{config} = EVE::Config->read( $file )
				or Carp::croak(
					"Failed to load config file"
					. $self->config_file
				);
		} else {
			if ( $self->config_file ) {
				Carp::croak(
					"Failed to find config file "
					. $self->config_file
				);
			} else {
				# Don't need a config
				$self->{config} = {};
			}
		}
	}

	# We need a username and password
	unless ( Params::Util::_IDENTIFIER($self->username) ) {
		Carp::croak("Did not provide a username");
	}
	unless ( Params::Util::_STRING($self->password) ) {
		Carp::croak("Did not provide a password");
	}

	# Set up the market log capture mechanism
	unless ( $self->marketlogs ) {
		$self->{marketlogs} = EVE::MarketLogs->new(
			dir => File::Spec->catdir(
				File::HomeDir->my_documents,
				'EVE', 'logs', 'Marketlogs',
			),
		);
	}

	# Find the image search patterns
	unless ( $self->patterns ) {
		$self->{patterns} = $self->find_patterns(
			File::Spec->catdir(
				File::ShareDir::dist_dir('EVE'),
				'vision',
			),
		);
	}

	# Initialise the screenshot variables
	$self->{screenshot}      = undef;
	$self->{screenshot_time} = 0;

	return $self;
}

sub userid {
	$_[0]->{userid} || $_[0]->config->userid;
}

sub username {
	$_[0]->{username} || $_[0]->config->username;
}

sub password {
	$_[0]->{password} || $_[0]->config->password;
}

sub api_limited {
	$_[0]->{api_limited} || $_[0]->config->api_limited;
}

sub api_full {
	$_[0]->{api_full} || $_[0]->config->api_full;
}

sub start {
	my $self = shift->new(@_);

	# Are we already running?
	if ( $self->find_windows ) {
		Carp::croak("An instance of EVE is already running");
	}

	# Is the server up?
	unless ( EVE::API->server_open ) {
		Carp::croak("Server is not up");
	}

	# Launch EVE, wait a bit, then find the login screen.
	# This is the only place we should use raw sleep calls.
	$self->launch;
	sleep 30;
	$self->attach;
	$self->connect;

	# Check that the screen size is 1024x768
	my $screenshot = $self->screenshot;
	unless ( $screenshot->width == 1024 and $screenshot->height == 768 ) {
		$self->throw("EVE is not running at 1024x768");
	}

	return $self;
}

# Kill the EVE session
sub stop {
	my $self = shift;

	# Stop the process
	unless ( $self->process ) {
		die("No process handle, unable to stop EVE");
	}
	$self->process->Kill(0);

	return 1;
}





#####################################################################
# Logical Functions

sub login {
	my $self = shift;

	# On Windows Vista or later you can't just make something else
	# the foreground window unless you current own it. For eve, we
	# can use a keypress to stimulate it to the front regardless.
	$self->send_keys("\t");

	# Click in the username box
	$self->left_click( MOUSE_LOGIN_USERNAME );

	# Clear out the old username (if it exists)
	$self->send_keys( '{BACKSPACE 30}' );

	# Enter the username
	$self->send_keys( $self->username );

	# Change to the password field
	$self->send_keys( "\t" );

	# Enter the password
	$self->send_keys( $self->password );

	# Change to the connect button and connect
	$self->send_keys( "\t~" );

	# Wait till we get to the user screen
	unless ( $self->wait_patterns( 30 => 'info-medium' ) ) {
		$self->throw("Failed to reach the user selection screen");
	}

	# Move the mouse to the current user and select
	$self->left_click( MOUSE_LOGIN_CURRENT_CHARACTER );

	# Wait till we get into the game
	unless ( $self->wait_pattern( 30 => 'neocom-character' ) ) {
		$self->throw("Failed to reach the main game");
	}

	# If the neocom is expanded, shrink it.
	my $minimize = $self->screenshot_has('neocom-minimize');
	if ( $minimize ) {
		$self->left_click($minimize);
		$self->sleep(1);
	}

	# If we're not docked, panic and quit
	unless ( $self->docked ) {
		$self->throw("Not docked! Panic!");
	}

	# Reset all window positions
	$self->reset_windows;

	# If the chat window is open, minimize it for safety
	$self->chat_minimize;

	return 1;
}

sub reset_windows {
	my $self = shift;

	# Assuming we aren't already at the quit screen, hit escape
	$self->send_keys( '{ESCAPE}' );
	$self->sleep(3);

	# Click on the fixed location of the reset tab
	$self->left_click( MOUSE_ESCAPE_RESET_TAB );

	# Reset the windows
	$self->left_click( MOUSE_ESCAPE_RESET_WINDOWS );

	# Hit escape again to exit the escape menu
	$self->send_keys( '{ESCAPE}' );
	unless ( $self->wait_pattern( 10 => 'neocom-mail' ) ) {
		$self->throw("Failed to return to the main game");
	}

	return 1;
}

sub region {
	$_[0]->{region} or $_[0]->throw("Have not initialised a region");
}





#####################################################################
# Market Interface

sub market_start {
	my $self = shift;

	# Open the market window
	$self->left_click( MOUSE_NEOCOM_MARKET );
	$self->sleep(1);
	unless ( $self->market_visible ) {
		$self->throw("Failed to open market window");
	}

	# Make sure the market is in search mode and details mode
	$self->left_click( MOUSE_MARKET_SEARCH_TAB  );
	$self->sleep(0.5);
	$self->left_click( MOUSE_MARKET_DETAILS_TAB );

	# Clear any previous search term
	$self->left_click( MOUSE_MARKET_SEARCH_TEXT );
	$self->sleep(0.5);
	$self->send_keys( '{DELETE 32}' );

	# Search for Trit so we can capture the current region in advance.
	$self->marketlogs->flush;
	unless ( $self->market_search('Tritanium', 2) ) {
		$self->throw("No trit, can't locate market");
	}
	my @trit = $self->marketlogs->parse_markets;
	unless ( @trit == 1 ) {
		$self->throw("Did not find the trit market");
	}
	$self->{region} = $trit[0]->region_name;

	return 1;
}

sub market_orders {
	my $self = shift;

	# Open the market window
	$self->left_click( MOUSE_NEOCOM_MARKET );
	$self->sleep(1);
	unless ( $self->market_visible ) {
		$self->throw("Failed to open market window");
	}

	# Make sure the market is in search mode and details mode
	$self->left_click( MOUSE_MARKET_ORDERS_TAB  );
	$self->sleep(2);

	# Clear any previous search term
	$self->marketlogs->flush;
	$self->left_click( MOUSE_MARKET_EXPORT_ORDERS );
	$self->sleep(2);
	$self->marketlogs->parse_orders;
}

sub market_groups {
	my $self  = shift;
	my $total = 0;
	foreach my $group ( @_ ) {
		$total += $self->market_group($group);
	}
	return $total;
}

sub market_group {
	my $self = shift;
	my $group = shift;
	if ( Params::Util::_POSINT($group) ) {
		$group = EVE::DB::InvMarketGroups->load($group);
	}
	unless ( Params::Util::_INSTANCE($group, 'EVE::DB::InvMarketGroups') ) {
		$self->throw("Did not provide an EVE::DB::InvMarketGroups to market_group");
	}

	# Fetch all types in the group
	my @types = EVE::DB::InvTypes->select(
		'where marketGroupID = ?',
		$group->marketGroupID,
	) or $self->throw("Failed to find any products for group");

	# Hand off to process the type set
	$self->market_types(@types);
}

sub market_types {
	my $self  = shift;
	my $total = 0;
	foreach my $type ( @_ ) {
		$total += $self->market_type($type);
	}
	return $total;
}

sub market_type {
	my $self = shift;
	my $type = shift;
	if ( Params::Util::_POSINT($type) ) {
		$type = EVE::DB::InvTypes->load($type);
	}
	unless ( Params::Util::_INSTANCE($type, 'EVE::DB::InvTypes') ) {
		$self->throw("Did not provide an EVE::DB::InvTypes to market_type");
	}

	# Determine which search result of N that may return is the real one
	my $name  = $type->typeName;
	my @named = EVE::DB::InvTypes->select(
		'where typeName like ? and marketGroupID is not null order by typeName',
		'%' . substr($name, 0, 32) . '%',
	);

	# If we can find a specific nth hit, scan with that number
	foreach my $i ( 0 .. $#named ) {
		next unless $named[$i]->typeName eq $name;

		# Flush existing market logs
		$self->marketlogs->flush;

		# Run the in-game search
		my $got = $self->market_search( substr($name, 0, 32), $i + 1 );
		if ( $got ) {
			# Scan the resulting market logs generated
			my $rv = $self->marketlogs->parse_markets;
			unless ( $rv == 1 ) {
				$self->throw("Did not find one market log file (Found $rv)");
			}
		} else {
			# No buy or sell orders, or super laggy market.
			# Blank the market
			EVE::MarketLogs->blank( $self->region, $name );
		}

		return 1;
	}

	$self->throw("Failed to pre-calculate nth result for product '$name'");
}

sub market_search {
	my $self    = shift;
	my $product = shift;
	my $nth     = shift || 1;
	my $chars   = length $product;

	# Ensure we have selected the search box
	$self->left_click( MOUSE_MARKET_SEARCH_TEXT );
	$self->sleep(0.5);

	# Search for what we want
	$self->send_keys( $product . "~" );
	$self->sleep(0.5);
	$self->send_keys( "{BACKSPACE $chars}{ESCAPE}" );
	$self->sleep(1);

	# Scan for product hits
	my @hits = sort {
		$a->top <=> $b->top
	} grep {
		$_->left > 250 and $_->left < 325
	} $self->screenshot_find('info-small');

	# Click on the nth hit
	my $hit = $hits[$nth - 1];
	if ( $hit ) {
		# Take the quick option of clicking on it
		$self->left_click( $hit->left - 10, $hit->centre_y );
		$self->sleep(3);
	} elsif ( @hits ) {
		# Take the slower option of incrementing down
		$hit = $hits[0];
		$self->left_click( $hit->left - 10, $hit->centre_y );
		$self->sleep(1);
		foreach ( 0 .. $nth - 2 ) {
			$self->send_keys('{DOWN}');
			sleep(1);
		}
		sleep(2);
	} else {
		die "Failed to find any hits, wtf?";
	}

	unless ( $self->wait_patterns( 10 => 'market-jumps' ) ) {
		return 0;
	}
	$self->left_click( MOUSE_MARKET_EXPORT_MARKET );

	return 1;
}

sub market_visible {
	my $self    = shift;
	my @matches = $self->screenshot_find('market-window');
	if ( @matches > 1 ) {
		$self->throw("More than one market window detected");
	} elsif ( @matches ) {
		return $matches[0];
	} else {
		return undef;
	}
}





#####################################################################
# Chat Interface

sub chat_minimize {
	my $self = shift;

	# Is the chat window open?
	my $open = $self->screenshot_has('chat-open-channel');
	unless ( $open ) {
		return 0;
	}

	# Close the chat window
	$self->left_click( $open->left, $open->top );
	if ( $self->screenshot_has('chat-open-window') ) {
		$self->throw("Failed to close chat window");
	}

	return 1;
}





#####################################################################
# Autopilot

sub autopilot_undock {
	my $self = shift->foreground;

	# We should be docked
	unless ( $self->docked ) {
		$self->throw("Can't undock while not docked");
	}

	# Find the undock button
	my $undock = $self->screenshot_has('neocom-undock');
	unless ( $undock ) {
		$self->throw("Can't find undock");
	}
	$self->left_click($undock);
	$self->sleep(15);

	return 1;
}

sub autopilot_system {
	my $self = shift->foreground;
	my $name = shift;

	# Open the People and Places window
	$self->left_click( MOUSE_NEOCOM_PLACES );
	unless ( $self->wait_pattern( 5 => 'places-header' ) ) {
		$self->throw("Failed to open places dialog");
	}

	# Is it set to solar system search
	unless ( $self->screenshot_has('places-search-solar-system') ) {
		$self->throw("Places dialog not set to solar system search");
	}

	# Select the search box
	$self->send_keys( '{TAB 4}' );
	$self->sleep(0.5);

	# Enter the name of the system
	$self->send_keys( $name . '~' );
	unless ( $self->wait_pattern( 5 => 'places-solar-systems' ) ) {
		$self->throw("Failed to open solar system search");
	}

	# Right click on the first result
	my $result = $self->screenshot_has('places-search-first-result');
	$self->throw("Failed to find the first result") unless $result;
	$self->right_click( $result->center_x + 20, $result->center_y );

	# Click on Set Destination
	my $set = $self->wait_pattern( 5 => 'context-set-destination' );
	$self->throw("Failed to find Set Destination context menu") unless $set;
	$self->left_click($set);
	$self->sleep(1);

	# Close the search results
	my $close = $self->screenshot_has('gui-close-window')
		or $self->throw("Can't find close window control");

	$self->left_click( MOUSE_PLACES_RESULT_CLOSE );
	$self->mouse_to( MOUSE_PLACES_CLOSE );
	$self->sleep(1);

	# Close places
	$self->sleep(1);
	$self->left_click( MOUSE_PLACES_CLOSE );

	return 1;
}

sub autopilot_station {
	my $self = shift->foreground;
	my $name = shift;

	# Open the People and Places window
	$self->left_click( MOUSE_NEOCOM_PLACES );
	unless ( $self->wait_pattern( 5 => 'places-header' ) ) {
		$self->throw("Failed to open places dialog");
	}

	# Is it set to solar system search
	unless ( $self->screenshot_has('places-search-station') ) {
		$self->throw("Places dialog not set to solar system search");
	}

	# Select the search box
	$self->send_keys( '{TAB 4}' );
	$self->sleep(0.5);

	# Enter the name of the system
	$self->send_keys( $name . '~' );
	unless ( $self->wait_pattern( 5 => 'places-stations' ) ) {
		$self->throw("Failed to open solar system search");
	}

	# Right click on the first result
	my $result = $self->screenshot_has('places-search-first-result');
	unless ( $result ) {
		$self->throw("Failed to find the first result");
	}
	$self->right_click( $result->center_x + 20, $result->center_y );
	my $set = $self->wait_pattern( 5 => 'context-set-destination' )
		or $self->throw("Failed to find Set Destination context menu");

	# Left click on Set Destination
	$self->left_click($set);
	$self->sleep(1);

	# Close the search results
	my $close = $self->screenshot_has('gui-close-window')
		or $self->throw("Can't find close window control");

	$self->left_click( MOUSE_PLACES_RESULT_CLOSE );
	$self->mouse_to( MOUSE_PLACES_CLOSE );
	$self->sleep(1);

	# Close places
	$self->sleep(1);
	$self->left_click( MOUSE_PLACES_CLOSE );

	return 1;
}

sub autopilot_engage {
	my $self  = shift->foreground;
	my $jumps = 0;

	# Constantly look for and mouseover the destination gate
	while ( 1 ) {
		# Is a destination gate selected
		my $selected = $self->screenshot_has('overview-destination-selected');
		if ( $selected ) {
			# Can we jump to a new system
			if ( $self->autopilot_can_jump ) {
				# Jump to the new system
				while ( not $self->screenshot_black(COLOR_SELECTED_JUMP) ) {
					$self->left_click(COLOR_SELECTED_JUMP);
					$self->sleep(0.5);
				}

				# Because the autopilot will never take you into
				# a dead end system and then take you back out,
				# there must always be one non-destination gate.
				# The appearance of such indicates arrival in
				# the destination system
				unless ( $self->wait_patterns( 60 => 'overview-gate' ) ) {
					# We may have jumped into somewhere like
					# Jita with so many ships it is
					# obscuring the gate.
					# Try engaging the in-game autopilot to
					# get away from the gate and into
					# transit to the next gate.
					$self->send_keys('^s');
					$self->wait_patterns( 30 => 'overview-gate' )
					or $self->throw("Failed to complete jump to new system");
				}
				$jumps++;
				next;
			}

			# Can we warp to the selected gate
			if ( $self->autopilot_can_warp ) {
				# Warp to the gate
				$self->left_click( COLOR_SELECTED_WARP_TO );
				$self->sleep(0.5);
				next;
			}

			# Can we approach the selected gate
			if ( $self->autopilot_can_approach ) {
				# Approach the gate
				$self->left_click( COLOR_SELECTED_APPROACH );
				$self->sleep(0.5);
				next;
			}

			# No navigation options at all, we are probably in warp
			$self->sleep(1);
			next;
		}

		# Select the next destination gate.
		# If it isn't on screen, give it a short time to reappear.
		my $gate = $self->wait_pattern( 5 => 'overview-destination' );
		if ( $gate ) {
			# Select the gate
			$self->left_click($gate);
			$self->mouse_to( 2, 2 );
			$self->sleep(0.5);
			next;
		}

		# There is no destination gate, exit the autopilot
		last;
	}

	return $jumps;
}

sub autopilot_can_approach {
	my $self = shift;

	# The pixel to the left must be black
	my $black = $self->screenshot_black(
		COLOR_SELECTED_APPROACH->[0] - 1,
		COLOR_SELECTED_APPROACH->[1],
	) or $self->throw("Pixel left of target not black... panic");

	# Check the intensity of the pixel we care about
	my $color = $self->screenshot_color(COLOR_SELECTED_APPROACH);
	my $value = ($color->hsv)[2];
	if ( $value > 0.4 ) {
		return 1;
	} elsif ( $value > 0.2 ) {
		return 0;
	} else {
		$self->throw("Unexpected color at COLOR_SELECTED_APPROACH");
	}
}

sub autopilot_can_warp {
	my $self  = shift;

	# The pixel to the left must be black
	my $black = $self->screenshot_black(
		COLOR_SELECTED_WARP_TO->[0] - 1,
		COLOR_SELECTED_WARP_TO->[1],
	) or $self->throw("Pixel left of target not black... panic");

	# Check the intensity of the pixel we care about
	my $color = $self->screenshot_color(COLOR_SELECTED_WARP_TO);
	my $value = ($color->hsv)[2];
	if ( $value > 0.4 ) {
		return 1;
	} elsif ( $value > 0.2 ) {
		return 0;
	} else {
		$self->throw("Unexpected color at COLOR_SELECTED_WARP_TO");
	}
}

sub autopilot_can_jump {
	my $self = shift;

	# The pixel to the left must be black
	my $black = $self->screenshot_black(
		COLOR_SELECTED_JUMP->[0] - 1,
		COLOR_SELECTED_JUMP->[1],
	) or $self->throw("Pixel left of target not black... panic");

	# Check the intensity of the pixel we care about
	my $color = $self->screenshot_color(COLOR_SELECTED_JUMP);
	my $value = ($color->hsv)[2];
	if ( $value > 0.4 ) {
		return 1;
	} elsif ( $value > 0.2 ) {
		return 0;
	} else {
		$self->throw("Unexpected color at COLOR_SELECTED_JUMP");
	}
}





#####################################################################
# State Information

# Are we in the main game and docked in a station
sub docked {
	my $self = shift;
	$self->screenshot_has('station-information') and return 1;
	$self->screenshot_has('neocom-undock')       and return 1;
	return 1;
}





#####################################################################
# Basic Functions

# Ensure EVE is the foreground window, returns the object as a convenience
sub foreground {
	my $self = shift;
	if ( $self->window == Win32::GuiTest::GetForegroundWindow() ) {
		# Already front window, nothing to do
		return $self;
	}

	Win32::GuiTest::SetForegroundWindow($self->window);
	Win32::GuiTest::SetActiveWindow($self->window);
	Win32::GuiTest::SetFocus($self->window);
	$self->mouse_to(1,1);
	Win32::GuiTest::SendLButtonDown();
	$self->sleep(0.2);
	Win32::GuiTest::SendLButtonUp();
	$self->sleep(1);

	if ( $self->window == Win32::GuiTest::GetForegroundWindow() ) {
		# Already front window, nothing to do
		return $self;
	}

	die "Failed to set EVE to front window";
}

# Type something or send keys
sub send_keys {
	my $self = shift->foreground;
	Win32::GuiTest::SendKeys(shift);
	return 1;
}

# Find the current mouse co-ordinate relative to the window
sub mouse_xy {
	my $self = shift->foreground;
	return [
		Win32::GuiTest::ScreenToClient(
			$self->window,
			Win32::GuiTest::GetCursorPos(),
		)
	];
}

# Move the mouse to a particular position
sub mouse_to {
	my $self = shift;
	my $to   = $self->coord(@_);

	# Move the mouse to the window-relative position
	Win32::GuiTest::MouseMoveAbsPix(
		Win32::GuiTest::ClientToScreen( $self->window, @$to )
	);

	return 1;
}

# Move the mouse rapidly around a set of matches images to identify where they
# are seen.
sub mouse_flicker {
	my $self = shift;

	# Convert the matches into points
	my @points = ();
	foreach my $match ( @_ ) {
		push @points, (
			[ $match->left,  $match->top    ],
			[ $match->left,  $match->bottom ],
			[ $match->right, $match->bottom ],
			[ $match->right, $match->top    ],
		);
	}

	# Move the mouse to each of the points
	foreach my $point ( ( @points ) x 5 ) {
		$self->mouse_to($point);
		# $self->sleep(0.05);
	}

	return 1;
}

sub left_click {
	my $self = shift->foreground;
	my $here = $self->mouse_xy;

	# Move the mouse to the target, allow time for transition effects
	$self->mouse_to(@_) if @_;
	$self->sleep(0.2);

	# Click whatever it is nice and slow
	Win32::GuiTest::SendLButtonDown();
	$self->sleep(0.3);
	Win32::GuiTest::SendLButtonUp();
	$self->screenshot_dirty;

	# Return the mouse to the rest position to prevent unwanted tooltips
	$self->mouse_to($here) if @_;

	return 1;
}

sub right_click {
	my $self = shift->foreground;

	# Move the mouse to the target, allow time for transition effects
	$self->mouse_to(@_) if @_;
	$self->sleep(0.2);

	# Click whatever it is nice and slow
	Win32::GuiTest::SendRButtonDown();
	$self->sleep(0.2);
	Win32::GuiTest::SendRButtonUp();
	$self->screenshot_dirty;

	# Don't return to anywhere on right click, because it could
	# break the spawning of the context menu.

	return 1;
}





#####################################################################
# Vision Support

sub pattern {
	my $self    = shift;
	my $name    = shift;
	my $pattern = ref($name)
		? EVE::TextPattern->new( name => $$name )
		: $self->patterns->{$name};
	unless ( $pattern ) {
		$self->throw("Image pattern '$name' does not exist");
	}
	return $pattern;
}

# Load named pattern objects for a directory
sub find_patterns {
	my $self = shift;
	my $path = shift;
	unless ( -d $path ) {
		$self->throw("Directory '$path' does not exist");
	}

	# Scan for pattern files
	my @files = File::Find::Rule->relative->file('*.bmp')->in($path);

	# Load the patterns
	my %hash = ();
	foreach my $file ( @files ) {
		my $name = $file;
		$name =~ s/\.bmp$//;
		$hash{$name} = Imager::Search::Pattern->new(
			name   => $name,
			driver => 'Imager::Search::Driver::BMP24',
			file   => File::Spec->catfile( $path, $file ),
			cache  => 1,
		);
	}

	\%hash;
}

# Screenshots become automatically stale after 1 second
sub screenshot {
	my $self = shift;
	if ( Time::HiRes::time() - $self->{screenshot_time} ) {
		$self->screenshot_dirty;
	}
	unless ( $self->{screenshot} ) {
		$self->{screenshot} = Imager::Search::Screenshot->new(
			[ hwnd => $self->window ],
			driver => 'BMP24',
		);
	}
	return $self->{screenshot};
}

sub screenshot_dirty {
	$_[0]->{screenshot} = undef;
}

# Search for a pattern in a screenshot (should only exist once)
sub screenshot_has {
	my $self = shift;
	my $name = shift;
	my @list = $self->screenshot_find($name);
	if ( @list > 1 ) {
		$self->throw("Unexpectedly found '$name' more than once");
	}
	return $list[0];
}

# Search for a pattern in a screenshot (more than once)
sub screenshot_find {
	my $self = shift;
	my $name = shift;
	my @list = $self->screenshot->find(
		$self->pattern($name)
	);
	if ( $self->{debug_pattern} and @list ) {
		$self->mouse_flicker(@list);
	}
	return @list;
}

# Find the current colour at a single co-ordinate.
# Returns an Imager::Color
sub screenshot_color {
	my $self  = shift->foreground;
	my $coord = $self->coord(@_);
	my $color = $self->screenshot->image->getpixel(
		x => $coord->[0],
		y => $coord->[1],
	);
	# $self->mouse_to( $coord );
	return $color;
}

# Is the colour at a particular point black, or very close to it
sub screenshot_black {
	my $self  = shift;
	my $color = $self->screenshot_color(@_);
	my $value = ($color->hsv)[2];
	if ( $value < 0.05 ) {
		return 1;
	} else {
		return 0;
	}
}





#####################################################################
# Process Mechanics

sub throw {
	my $self    = shift;
	my $message = shift;
	if ( $self->process and $self->paranoid ) {
		$self->stop;
	}
	Carp::croak($message);
}

sub coord {
	my $self = shift;
	if ( @_ == 1 ) {
		if ( Params::Util::_INSTANCE($_[0], 'Imager::Search::Match') ) {
			return [ $_[0]->centre_x, $_[0]->centre_y ];

		} elsif ( $_[0] =~ /^(\d+)[^\d]+(\d+)$/ ) {
			return [ $1+0, $2+0 ];

		} elsif ( ref $_[0] eq 'ARRAY' ) {
			Params::Util::_POSINT($_[0]->[0]) or $self->throw("Invalid X position '$_[0]->[0]'");
			Params::Util::_POSINT($_[0]->[1]) or $self->throw("Invalid Y position '$_[0]->[1]'");
			return [ $_[0]->[0], $_[0]->[1] ];

		} else {
			$self->throw("Unrecognised position string '$_[0]'");
		}

	} elsif ( @_ == 2 ) {
		Params::Util::_POSINT($_[0]) or $self->throw("Invalid X position '$_[0]'");
		Params::Util::_POSINT($_[1]) or $self->throw("Invalid Y position '$_[1]'");
		return [ $_[0], $_[1] ];

	} else {
		$self->throw("Invalid or unknown position");
	}
}

# Launch the executable
sub launch {
	my $self = shift;

	# Be paranoid, if not we could just leave the game running
	$self->{paranoid} = 1;

	# We need an executable location
	my $process;
	my $rv = Win32::Process::Create(
		$process,
		$self->config->{_}->{exe} || "C:\\Program Files\\CCP\\EVE\\eve.exe",
		"eve",
		0,
		Win32::Process::NORMAL_PRIORITY_CLASS,
		".",
	);
	unless ( $rv and $process ){
		$self->throw("Failed to start EVE");
	}

	return 1;
}

# Update the process and window handles
sub attach {
	my $self = shift;

	# Clear the handles
	$self->{process} = undef;
	$self->{window}  = undef;

	# Locate the process
	my $process_list = Win32::Process::List->new;
	my ($name, $pid) = $process_list->GetProcessPid('ExeFile');
	return undef unless $pid;

	# Create the process handle
	Win32::Process::Open( $self->{process}, $pid, 0 );

	return 1;
}

# Connect to an existing instance of EVE
sub connect {
	my $self = shift;

	# Locate the EVE window
	unless ( $self->window ) {
		$self->{window} = $self->find_window;
	}

	return $self;
}

# Find all eve windows
sub find_windows {
	Win32::GuiTest::FindWindowLike(0, '^EVE$');
}

# Find the (presumably only) EVE window
sub find_window {
	my $self    = shift;
	my @windows = $self->find_windows;
	unless ( @windows ) {
		$self->throw("EVE is not running");
	}
	unless ( @windows == 1 ) {
		$self->throw("Detected more than one EVE window");
	}
	return $windows[0];
}

# Do various cheap checks to confirm things are still ok
sub check {
	my $self = shift;

	# Confirm EVE is still running
	my $window = $self->find_window;
	unless ( $window == $self->window ) {
		$self->throw("EVE window id has unexpectedly changed");
	}

	return 1;
}

# Sleep for a period of time, and at the end validate EVE is still running
# and we are attached to it.
sub sleep {
	my $self    = shift;
	my $seconds = shift;
	unless ( Params::Util::_NUMBER($seconds) ) {
		$seconds = $self->config->{sleep}->{$seconds};
	}
	unless ( Params::Util::_NUMBER($seconds) ) {
		$self->throw("Missing or invalid sleep time");
	}

	# Do the sleep itself
	Time::HiRes::sleep($seconds);

	# When we wait for something we expect things to change
	$self->screenshot_dirty;

	# Make sure things are ok after the sleep
	$self->check;

	return 1;
}

sub wait_pattern {
	my $self = shift;
	my @list = $self->wait_patterns(@_);
	if ( @list > 1 ) {
		$self->throw("Matched more than one pattern... panic!");
	}
	return $list[0];
}

sub wait_patterns {
	my $self     = shift;
	my $time     = time + shift;
	my @patterns = map { $self->pattern($_) } @_;

	while ( time < $time ) {
		# Can we see any of the patterns on the screen
		my $screenshot = $self->screenshot;
		my @matches    = map { $screenshot->find($_) } @patterns;
		return @matches if @matches;

		# Wait a bit
		$self->sleep(0.5);
	}

	return;
}

sub wait_until {
	my $self = shift;
	my $time = time + shift;
	my $code = Params::Util::_CODE(shift) or die "Did not pass a CODE reference";

	while ( time < $time ) {
		# Is the condition true
		my $rv = $code->($self);
		return $rv if $rv;

		# Wait a bit
		$self->sleep(0.5);
	}

	return;
}

1;
