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
use Imager::Search        1.01 ();
use Imager::Search::Pattern    ();
use Imager::Search::Screenshot ();
use EVE::MarketLogs            ();

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
# Screen Location Constants

use constant {
	MOUSE_LOGIN_USERNAME          => [ 552, 687 ],
	MOUSE_LOGIN_CURRENT_CHARACTER => [ 170, 273 ],
	MOUSE_ESCAPE_RESET_TAB        => [ 522, 164 ],
	MOUSE_ESCAPE_RESET_WINDOWS    => [ 614, 209 ],
	MOUSE_NEOCOM_MARKET           => [ 18,  262 ],
	MOUSE_MARKET_DETAILS_TAB      => [ 438, 111 ],
	MOUSE_MARKET_SEARCH_TAB       => [ 195, 200 ],
	MOUSE_MARKET_SEARCH_TEXT      => [ 121, 226 ],
	MOUSE_MARKET_EXPORT_TO_FILE   => [ 613, 670 ],
};





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
			$self->{config} = Config::Tiny->read( $file )
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

sub username {
	$_[0]->{username} || $_[0]->config->{'_'}->{username};
}

sub password {
	$_[0]->{password} || $_[0]->config->{'_'}->{password};
}

# Create a new EVE instance
sub start {
	my $self = shift->new(@_);

	# Are we already running?
	if ( $self->find_windows ) {
		Carp::croak("An instance of EVE is already running");
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
	$self->wait( 20 => 'info-medium' );

	# Move the mouse to the current user and select
	$self->left_click( MOUSE_LOGIN_CURRENT_CHARACTER );

	# Wait till we get into the game
	$self->sleep(20);

	# If the neocom is expanded, shrink it.
	my $minimize = $self->screenshot_has('neocom-minimize');
	if ( $minimize ) {
		$self->left_click($minimize);
		$self->sleep(1);
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
	$self->sleep(3);

	return 1;
}





#####################################################################
# Market Interface

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

sub market_start {
	my $self = shift;

	# Click the neocom market icon to ensure it should be on the screen
	$self->left_click( MOUSE_NEOCOM_MARKET );
	$self->sleep(1);
	unless ( $self->market_visible ) {
		$self->throw("Failed to open market window");
	}

	# Make sure the market is in search mode and details mode
	$self->left_click( MOUSE_MARKET_SEARCH_TAB  );
	$self->left_click( MOUSE_MARKET_DETAILS_TAB );

	return 1;
}

sub market_scan {
	my $self    = shift;
	my $product = shift;

	# Flush existing market logs
	$self->marketlogs->flush;

	# Run the in-game search
	$self->market_search($product);

	# Scan the resulting market logs generated
	$self->marketlogs->parse_all;

	return 1;
}

sub market_search {
	my $self    = shift;
	my $product = shift;

	# Clear any previous search term
	$self->left_click( MOUSE_MARKET_SEARCH_TEXT );
	$self->sleep(0.5);
	$self->send_keys( '{DELETE 100}' );

	# Search for what we want
	$self->send_keys( $product . "~" );
	$self->sleep(3);

	# Scan for product hits
	my @hits = grep {
		$_->left > 375 and $_->left < 400
	}$self->screenshot_find('info-small');

	# Click on each of the hits to bring up their market information and
	# export it to a file on disk.
	foreach my $hit ( @hits ) {
		$self->left_click( $hit->left - 20, $hit->centre_y );
		$self->sleep(5);

		if ( $self->screenshot_find('market-no-orders-found') > 1 ) {
			# No buy or sell orders
			next;
		}

		$self->left_click( MOUSE_MARKET_EXPORT_TO_FILE );
	}

	return 1;
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
# Get Information

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





#####################################################################
# Basic Functions

# Ensure EVE is the foreground window, returns the object as a convenience
sub foreground {
	my $self = shift;
	Win32::GuiTest::SetForegroundWindow($self->window);
	Win32::GuiTest::SetActiveWindow($self->window);
	Win32::GuiTest::SetFocus($self->window);
	$self->sleep(1);
	return $self;
}

# Type something or send keys
sub send_keys {
	my $self = shift->foreground;
	Win32::GuiTest::SendKeys(shift);
	return 1;
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

	# Click whatever it is nice and slow
	Win32::GuiTest::SendLButtonDown();
	$self->sleep(0.1);
	Win32::GuiTest::SendLButtonUp();

	# Return the mouse to the rest position to prevent unwanted tooltips
	$self->mouse_to($here) if @_;

	return 1;
}

sub right_click {
	my $self = shift->foreground;

	# Move the mouse to the target, allow time for transition effects
	$self->mouse_to(@_) if @_;
	$self->sleep(0.5);

	# Click whatever it is nice and slow
	Win32::GuiTest::SendRButtonDown();
	$self->sleep(0.5);
	Win32::GuiTest::SendRButtonUp();

	# Return the mouse to the rest position to prevent unwanted tooltips
	$self->mouse_to( [ 2, 2 ] ) if @_;

	return 1;
}





#####################################################################
# Vision Support

sub pattern {
	my $self = shift;
	my $name = shift;
	my $pattern = $self->patterns->{$name};
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

	# Confirm EVE is still running
	my $window = $self->find_window;
	unless ( $window == $self->window ) {
		$self->throw("EVE window id has unexpectedly changed");
	}

	return 1;
}

sub wait {
	my $self     = shift;
	my $time     = time + shift;
	my @patterns = map { $self->pattern(@_) } @_;

	while ( time < $time ) {
		# Can we see any of the patterns on the screen
		my $screenshot = $self->screenshot;
		my @matches    = map { $screenshot->find($_) } @patterns;
		return @matches if @matches;

		# Wait a bit
		$self->sleep(1);
	}

	return;
}

1;
