package Kephra::Config::File;
$VERSION = '0.03';

use strict;

sub load {
	my ( $configfilename, %config ) = shift;
	my $error_msg = $Kephra::localisation{'dialogs'}{'error'};
	if ( -e $configfilename ) {
		eval {
			$Kephra::app{config}{parser} = Config::General->new(
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
			%config = $Kephra::app{config}{parser}->getall;
		};
		Kephra::Dialog::warning_box (undef,
			"$configfilename: \n $@", $error_msg->{'config_read'})
				if $@ or !%config;
	} else {
		Kephra::Dialog::warning_box (undef,
			$error_msg->{config_read}." ".$configfilename, $error_msg->{file});
	}
	\%config;
}

sub store {
	my ( $configfilename, $config ) = @_;
	$Kephra::app{config}{parser}->save_file( $configfilename, $config );
}

1;
