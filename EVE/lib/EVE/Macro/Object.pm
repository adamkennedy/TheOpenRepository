package EVE::Macro::Object;

use 5.008;
use strict;
use warnings;
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
use Imager::Search        1.00 ();
use Imager::Search::Pattern    ();
use Imager::Search::Screenshot ();

our $VERSION = '0.01';

BEGIN {
	$Win32::GuiTest::debug = 0;

	sub Imager::Search::Match::centre_x {
		$_[0]->{centre_x};
	}

	sub Imager::Search::Match::centre_y {
		$_[0]->{centre_y};
	}

}

use Object::Tiny 1.08 qw{
	config
	config_file
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
	MOUSE_CHROME_MARKET           => [ 18,  262 ],
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Find and load the config file if it exists
	unless ( $self->config ) {
		# Are we looking for a specific config file
		my $file = $self->config_file || 'EVE-Macro.conf';
		unless ( File::Spec->file_name_is_absolute($file) ) {
			$file = File::Spec->catfile(
				File::HomeDir->my_documents,
				$file
				);
		}
		if ( -f $file ) {
			# Load the config file
			$self->{config} = Config::Tiny->read( $file )
				or die(
					"Failed to load config file"
					. $self->config_file
				);
		} else {
			if ( $self->config_file ) {
				die(
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
		die("Did not provide a username");
	}
	unless ( Params::Util::_STRING($self->password) ) {
		die("Did not provide a password");
	}

	# Try to find the market log directory
	unless ( $self->marketlogs ) {
		$self->{marketlogs} = File::Spec->catdir(
			File::HomeDir->my_documents,
			'EVE', 'logs', 'Marketlogs',
		);	
	}
	unless ( -d $self->marketlogs ) {
		die("Missing or invalid marketlogs directory");
	}

	# Find the image search patterns
	unless ( $self->patterns ) {
		$self->{patterns} = $self->find_patterns(
			File::Spec->catdir(
				File::ShareDir::dist_dir('EVE-Macro-Object'),
				'vision',
			),
		);
	}

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
		die("An instance of EVE is already running");
	}

	# Launch EVE, wait a bit, then find the login screen.
	# This is the only place we should use raw sleep calls.
	$self->launch;
	sleep 30;
	$self->attach;
	sleep 10;
	$self->connect;

	# Check that the screen size is 1024x768
	my $screenshot = $self->screenshot;
	unless ( $screenshot->width == 1024 and $screenshot->height == 768 ) {
		die "EVE is not running at 1024x768";
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
	$self->send_keys( '{BACKSPACE}' x 20 );

	# Enter the username
	$self->send_keys( $self->username );

	# Change to the password field
	$self->send_keys( "\t" );

	# Enter the password
	$self->send_keys( $self->password );

	# Change to the connect button and connect
	$self->send_keys( "\t~" );

	# Wait till we get to the user screen
	$self->sleep(20);

	# Move the mouse to the current user and select
	$self->left_click( MOUSE_LOGIN_CURRENT_CHARACTER );

	# Wait till we get into the game
	$self->sleep(20);

	# If the neocom is expanded, shrink it.
	my @matches = $self->screenshot_search('neocom-minimize');
	if ( @matches ) {
		die "Found more than one neocom-minimise" if @matches > 1;
		$self->left_click($matches[0]);
		$self->sleep(5);
	}

	return 1;
}

sub market_search {
	my $self    = shift;
	my $product = shift;

	# Click the market
	$self->left_click( MOUSE_CHROME_MARKET );
	$self->sleep(1);

	# If we aren't on the search tab switch to it
	my @tab = $self->screenshot_search('market-search-tab');
	if ( @tab == 1 ) {
		$self->left_click( $tab[0] );
		$self->sleep(1);
	}

	# Clear any previous search term
	my @search = $self->screenshot_search('market-search-button');
	unless ( @search == 1 ) {
		die "Failed to find search button";
	}
	$self->left_click( $search[0]->left - 20, $search[0]->centre_y );
	$self->sleep(1);
	$self->send_keys( '{BACKSPACE}' x 100 );

	# Search for what we want
	$self->send_keys( $product . "~" );
	$self->sleep(10);

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
	my $to   = _COORD(@_);

	# Move the mouse to the window-relative position
	Win32::GuiTest::MouseMoveAbsPix(
		Win32::GuiTest::ClientToScreen( $self->window, @$to )
	);

	return 1;
}

sub left_click {
	my $self = shift->foreground;

	# Move the mouse to the target, allow time for transition effects
	$self->mouse_to(@_) if @_;
	$self->sleep(1);

	# Click whatever it is nice and slow
	Win32::GuiTest::SendLButtonDown();
	$self->sleep(1);
	Win32::GuiTest::SendLButtonUp();

	# Return the mouse to the rest position to prevent unwanted tooltips
	$self->mouse_to( [ 1, 1 ] ) if @_;

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
	$_[0]->patterns->{$_[1]} or die "Image pattern '$_[1]' does not exist";
}

# Load named pattern objects for a directory
sub find_patterns {
	my $self = shift;
	my $path = shift;
	unless ( -d $path ) {
		die "Directory '$path' does not exist";
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

# Get the screenshot for the window
sub screenshot {
	Imager::Search::Screenshot->new(
		[ hwnd => $_[0]->window ],
		driver => 'BMP24',
	);
}

# Search for a pattern in a screenshot
sub screenshot_search {
	my $self = shift;
	my $name = shift;
	$self->screenshot->find(
		$self->pattern($name)
	);
}





#####################################################################
# Process Mechanics

# Launch the executable
sub launch {
	my $self = shift;

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
		die("Failed to start EVE");
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
		die("EVE is not running");
	}
	unless ( @windows == 1 ) {
		die("Detected more than one EVE window");
	}
	return $windows[0];
}

# Sleep for a period of time, and at the end validate EVE is still running
# and we are attached to it.
sub sleep {
	my $self    = shift;
	my $seconds = shift;
	unless ( Params::Util::_POSINT($seconds) ) {
		$seconds = $self->config->{sleep}->{$seconds};
	}
	unless ( Params::Util::_POSINT($seconds) ) {
		die("Missing or invalid sleep time");
	}

	# Do the sleep itself
	Time::HiRes::sleep($seconds);

	# Confirm EVE is still running
	my $window = $self->find_window;
	unless ( $window == $self->window ) {
		die("EVE window id has unexpectedly changed");
	}

	return 1;
}





#####################################################################
# Support Functions

sub _COORD {
	if ( @_ == 1 ) {
		if ( Params::Util::_INSTANCE($_[0], 'Imager::Search::Match') ) {
			return [ $_[0]->centre_x, $_[0]->centre_y ];
		} elsif ( $_[0] =~ /^(\d+)[^\d]+(\d+)$/ ) {
			return [ $1+0, $2+0 ];
		} elsif ( ref $_[0] eq 'ARRAY' ) {
			Params::Util::_POSINT($_[0]->[0]) or die("Invalid position X");
			Params::Util::_POSINT($_[0]->[1]) or die("Invalid position Y");
			return [ $_[0]->[0], $_[0]->[1] ];
		} else {
			die("Unrecognised position string");
		}
	} elsif ( @_ == 2 ) {
		Params::Util::_POSINT($_[0]) or die("Invalid position X");
		Params::Util::_POSINT($_[1]) or die("Invalid position Y");
		return [ $_[0], $_[1] ];
	} else {
		die("Invalid or unknown position");
	}
}

1;
