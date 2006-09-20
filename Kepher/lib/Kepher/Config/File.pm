package Kepher::Config::File;

use strict;
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.03';
}

sub load {
	my ( $configfilename, %config ) = shift;
	my $error_msg = $Kepher::localisation{'dialogs'}{'error'};
	if ( -e $configfilename ) {
		eval {
			$Kepher::app{config}{parser} = Config::General->new(
				-AutoTrue              => 1,
				-UseApacheInclude      => 1,
				-IncludeRelative       => 1,
				-InterPolateVars       => 0,
				-AllowMultiOptions     => 1,
				-MergeDuplicateOptions => 0,
				-MergeDuplicateBlocks  => 0,
				-ConfigFile            => $configfilename,
				-SplitPolicy           => 'equalsign'
			);
			%config = $Kepher::app{config}{parser}->getall;
		};
		Kepher::Dialog::warning_box (undef,
			"$configfilename: \n $@", $error_msg->{'config_read'})
				if $@ or !%config;
	} else {
		Kepher::Dialog::warning_box (undef,
			$error_msg->{config_read}." ".$configfilename, $error_msg->{file});
	}
	\%config;
}

sub store {
	my ( $configfilename, $config ) = @_;
	$Kepher::app{config}{parser}->save_file( $configfilename, $config );
}

1;
