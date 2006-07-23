package KEPHER::Config::File;
$VERSION = '0.03';

use strict;

sub load {
	my ( $configfilename, %config ) = shift;
	my $error_msg = $KEPHER::localisation{'dialogs'}{'error'};
	if ( -e $configfilename ) {
		eval {
			$KEPHER::app{config}{parser} = Config::General->new(
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
			%config = $KEPHER::app{config}{parser}->getall;
		};
		KEPHER::Dialog::warning_box (undef,
			"$configfilename: \n $@", $error_msg->{'config_read'})
				if $@ or !%config;
	} else {
		KEPHER::Dialog::warning_box (undef,
			$error_msg->{config_read}." ".$configfilename, $error_msg->{file});
	}
	\%config;
}

sub store {
	my ( $configfilename, $config ) = @_;
	$KEPHER::app{config}{parser}->save_file( $configfilename, $config );
}

1;
