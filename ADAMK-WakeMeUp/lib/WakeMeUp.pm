package ADAMK::WakeMeUp;

# Wake me up before I have to go go

use strict;
use warnings;
use Params::Util qw{ _POSINT };
use Win32::MediaPlayer ();

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( _POSINT($self->sleep_for) ) {
		die("Missing or invalid sleep_for param");
	}
	unless ( $self->warm_file and -f $self->warm_file ) {
		die("Missing or invalid warm_file param");
	}
	unless ( _POSINT($self->wake_for) ) {
		die("Missing or invalid wake_for param");
	}
	unless ( $self->alarm_file and -f $self->alarm_file ) {
		die("Missing or invalid wake_file param");
	}

	return $self;
}

sub run {
	my $self = shift;

	# Load the warm file
	my $player = Win32::MediaPlayer->

	sleep($self->sleep_for);


	return 1;
}

1;
