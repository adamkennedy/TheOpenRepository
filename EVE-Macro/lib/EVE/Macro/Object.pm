package EVE::Macro::Object;

use 5.006;
use strict;
use Carp           'croak';
use File::Spec     ();
use Params::Util   qw{_POSINT _STRING};
use File::HomeDir  ();
use Config::Tiny   ();
use Win32::GuiTest ();
use Time::HiRes    ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
	$Win32::GuiTest::debug = 0;
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

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
				or croak(
					"Failed to load config file"
					. $self->config_file
				);
		} else {
			if ( $self->config_file ) {
				croak(
					"Failed to find config file "
					. $self->config_file
				);
			} else {
				# Don't need a config
				$self->{config} = {};
			}
		}
	}

	# Locate the EVE window
	unless ( $self->window ) {
		my @windows = Win32::GuiTest::FindWindowLike(0, '^EVE$');
		unless ( @windows ) {
			croak("EVE is not running");
		}
		unless ( @windows == 1 ) {
			croak("Detected more than one EVE window");
		}
		$self->{window} = $windows[0];
	}

	$self;
}

sub config {
	$_[0]->{config};
}

sub config_file {
	$_[0]->{config_file};
}

sub window {
	$_[0]->{window};
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
sub move_to {
	my $self = shift;
	my $to   = _COORD(@_);
	Win32::GuiTest::SetForegroundWindow($self->window);
	Win32::GuiTest::MouseMoveAbsPix($to->[0], $to->[1]);
	return 1;
}

# Clicking the mouse
sub left_click {
	my $self = shift;
	$self->move_to(@_) if @_;
	Win32::GuiTest::SendLButtonDown();
	Win32::GuiTest::SendLButtonUp();
	return 1;
}

sub right_click {
	my $self = shift;
	$self->move_to(@_) if @_;
	Win32::GuiTest::SendLButtonDown();
	Win32::GuiTest::SendLButtonUp();
	return 1;
}

# Select a menu option
sub left_click_left_menu {
	my $self     = shift;
	my $position = _POSINT(shift) or croak("Invalid menu number");
	my $config   = $self->config->{mouse_config} or die "No [mouse_config]";
	$self->left_click(
		$config->{left_menu_x},
		$config->{left_menu_y} + $config->{left_menu_d} * $position,
		);
}

# Click a named target
sub left_click_target {
	my $self   = shift;
	my $name   = shift or croak("No left_click_target provided");
	my $target = $self->config->{mouse_target}->{$name}
		or croak("No such [mouse_target] name '$name'");
	$self->left_click( $target );
}

sub right_click_target {
	my $self   = shift;
	my $name   = shift or croak("No left_click_target provided");
	my $target = $self->config->{mouse_target}->{$name}
		or croak("No such [mouse_target] name '$name'");
	$self->right_click( $target );
}

# Find the current mouse co-ordinate
sub mouse_pos {
	my $self    = shift;
	my ($x, $y) = Win32::GuiTest::GetCursorPos();
	return [ $x, $y ];
}

# Find the colour of a specific pixel
sub pixel_color {
	my $self  = shift;
	my $pixel = '';
}

# Wait for a defined period of time
sub sleep {
	my $self = shift;
	my $name = shift;
	my $period = $self->config->{'sleep'}->{$name}
		or croak("Invalid sleep '$name'");
	Time::HiRes::sleep( $period );
}





#####################################################################
# Support Functions

sub _COORD {
	if ( @_ == 1 ) {
		if ( $_[0] =~ /^(\d+)[^\d]+(\d+)$/ ) {
			return [ $1+0, $2+0 ];
		} elsif ( ref $_[0] eq 'ARRAY' ) {
			_POSINT($_[0]->[0]) or croak("Invalid position X");
			_POSINT($_[0]->[1]) or croak("Invalid position Y");
			return [ $_[0]->[0], $_[0]->[1] ];
		} else {
			croak("Unrecognised position string");
		}
	} elsif ( @_ == 2 ) {
		_POSINT($_[0]) or croak("Invalid position X");
		_POSINT($_[1]) or croak("Invalid position Y");
		return [ $_[0], $_[1] ];
	} else {
		croak("Invalid or unknown position");
	}
}

1;
