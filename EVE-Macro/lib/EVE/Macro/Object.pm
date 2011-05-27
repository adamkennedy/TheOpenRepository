package EVE::Macro::Object;

use 5.008;
use strict;
use File::Spec            0.80 ();
use File::HomeDir         0.93 ();
use File::ShareDir        1.00 ();
use Params::Util          1.00 qw{ _POSINT _IDENTIFIER _STRING _INSTANCE };
use Config::Tiny          2.02 ();
use File::Find::Rule      0.32 ();
use Time::HiRes         1.9718 ();
use Win32::GuiTest        1.58 ();
use Win32::Process        0.14 qw{ STILL_ACTIVE NORMAL_PRIORITY_CLASS };
use Win32::Process::List  0.09 ();
use Win32                 0.39 ();
use Imager::Search        1.00 ();
use Imager::Search::Pattern    ();
use Imager::Search::Screenshot ();

our $VERSION = '0.01';

BEGIN {
	$Win32::GuiTest::debug = 0;
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
	MOUSE_LOGIN_CURRENT_CHARACTER => [ 250, 250 ],
	MOUSE_CHROME_MARKET           => [ 20,  280 ],
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
	unless ( _IDENTIFIER($self->username) ) {
		die("Did not provide a username");
	}
	unless ( _STRING($self->password) ) {
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

	# Tab to the username
	$self->send_keys( "\t\t" );

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
	$self->sleep(30);

	# Move the mouse to the current user and select
	$self->left_click( MOUSE_LOGIN_CURRENT_CHARACTER );

	# Wait till we get to the main login
	$self->sleep(30);

	return 1;
}

sub market_search {
	my $self    = shift;
	my $product = shift;

	# Click the market
	$self->left_click( MOUSE_CHROME_MARKET );
	$self->sleep(1);

	# Click the search tab
	$self->left_click( 125, 140 );
	$self->sleep(1);

	# Click the search box
	$self->left_click( 125, 160 );
	$self->sleep(1);

	# Enter the product name
	$self->send_keys( '{BACKSPACE}' x 40 );
	$self->send_keys( '{DELETE}'    x 40 );
	$self->send_keys( $product . '~' );
	$self->sleep(3);

	# Select the first resulting thing
	$self->left_click( 125, 185 );
	$self->sleep(5);

	# Export the market data
	$self->left_click( 450, 775 );
	$self->sleep(3);

	return 1;
}





#####################################################################
# Get Information

# Find the current mouse co-ordinate
sub mouse_xy {
	my $self    = shift;
	my ($x, $y) = Win32::GuiTest::GetCursorPos();
	return [ $x, $y ];
}

# Get the screenshot for the window
sub screenshot {
	my $self   = shift;
	my $screen = Imager::Search::Screenshot->new(
		[ hwnd => $self->window ],
	);
	unless ( _INSTANCE($screen, 'Imager') ) {
		die("Failed to capture screen");
	}
	return $screen;
}





#####################################################################
# Basic Functions

# Type something or send keys
sub send_keys {
	my $self   = shift;
	my $string = shift;
	Win32::GuiTest::SetForegroundWindow($self->window);
	Win32::GuiTest::SendKeys($string);
	return 1;
}

# Move the mouse to a particular position
sub mouse_to {
	my $self = shift;
	my $to   = _COORD(@_);

	# Show the window and capture current position
	Win32::GuiTest::SetForegroundWindow($self->window);
	my ($l,$t,$r,$b) = Win32::GuiTest::GetWindowRect($self->window);

	# Move the mouse to the window-relative position
	Win32::GuiTest::MouseMoveAbsPix(
		$to->[0] + $l,
		$to->[1] + $t,
	);

	return 1;
}

# Clicking the mouse
sub left_click {
	my $self = shift;
	$self->mouse_to(@_) if @_;
	Win32::GuiTest::SendLButtonDown();
	$self->sleep(1);
	Win32::GuiTest::SendLButtonUp();
	return 1;
}

sub right_click {
	my $self = shift;
	$self->mouse_to(@_) if @_;
	Win32::GuiTest::SendLButtonDown();
	Win32::GuiTest::SendLButtonUp();
	return 1;
}

# Select a menu option
sub left_click_left_menu {
	my $self     = shift;
	my $position = _POSINT(shift) or die("Invalid menu number");
	my $config   = $self->config->{mouse_config} or die "No [mouse_config]";
	return $self->left_click(
		$config->{left_menu_x},
		$config->{left_menu_y} + $config->{left_menu_d} * $position,
		);
}

# Click a named target
sub left_click_target {
	my $self   = shift;
	my $name   = shift or die("No left_click_target provided");
	my $target = $self->config->{mouse_target}->{$name}
		or die("No such [mouse_target] name '$name'");
	return $self->left_click( $target );
}

sub right_click_target {
	my $self   = shift;
	my $name   = shift or die("No left_click_target provided");
	my $target = $self->config->{mouse_target}->{$name}
		or die("No such [mouse_target] name '$name'");
	return $self->right_click( $target );
}

# Sleep for a period of time, and at the end validate EVE is still running
# and we are attached to it.
sub sleep {
	my $self    = shift;
	my $seconds = shift;
	unless ( _POSINT($seconds) ) {
		$seconds = $self->config->{sleep}->{$seconds};
	}
	unless ( _POSINT($seconds) ) {
		die("Missing or invalid sleep time");
	}

	# Do the sleep itself
	sleep($seconds);

	# Confirm EVE is still running
	my $window = $self->find_window;
	unless ( $window == $self->window ) {
		die("EVE window id has unexpectedly changed");
	}

	1;
}





#####################################################################
# Vision Support

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
		my $pattern = Imager::Search::Pattern->new(
			driver => 'Imager::Search::Driver::HTML24',
			file   => File::Spec->catfile( $path, $file ),
		);
		$file =~ s/\.bmp$//;
		$hash{$file} = $pattern;
	}

	\%hash;
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
		NORMAL_PRIORITY_CLASS,
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
	Win32::Process::Open(
		$self->{process},
		$pid,
		0,
	);

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





#####################################################################
# Support Functions

sub _COORD {
	if ( @_ == 1 ) {
		if ( $_[0] =~ /^(\d+)[^\d]+(\d+)$/ ) {
			return [ $1+0, $2+0 ];
		} elsif ( ref $_[0] eq 'ARRAY' ) {
			_POSINT($_[0]->[0]) or die("Invalid position X");
			_POSINT($_[0]->[1]) or die("Invalid position Y");
			return [ $_[0]->[0], $_[0]->[1] ];
		} else {
			die("Unrecognised position string");
		}
	} elsif ( @_ == 2 ) {
		_POSINT($_[0]) or die("Invalid position X");
		_POSINT($_[1]) or die("Invalid position Y");
		return [ $_[0], $_[1] ];
	} else {
		die("Invalid or unknown position");
	}
}

1;
