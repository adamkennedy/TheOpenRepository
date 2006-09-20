package Win32::Wix;

use strict;
use File::Which  ();
use File::Remove ();
use Params::Util '_STRING';
use IPC::Run3    ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Locate the candle.exe application
	$self->{candle_path} ||= File::Which::which('candle');
	unless ( $self->candle_path ) {
		Carp::croak("No candle_path provided and could not locate candle.exe in PATH");
	}
	unless ( -f $self->candle_path ) {
		Carp::croak("The candle_path '$self->{candle_path}' does not exist");
	}

	# Locate the light.exe application
	$self->{light_path} ||= File::Which::which('light');
	unless ( $self->light_path ) {
		Carp::croak("No light_path provided and could not locate light.exe in PATH");
	}
	unless ( -f $self->light_path ) {
		Carp::croak("The light_path '$self->{light_path}' does not exist");
	}

	# Did we get a valid wix path
	unless ( defined _STRING($self->wix_path) ) {
		Carp::croak("Did not provide a wix_path param");
	}
	unless ( $self->wix_path =~ /\.wix$/ ) {
		Carp::croak("The wix_path param is not to a .wix file");
	}
	unless ( -f $self->wix_path ) {
		Carp::croak("The wix_path file does not exist");
	}

	# Set the other paths from the wix_path
	$self->{base_path}   = $self->wix_path;
	$self->{base_path}   =~ s/\.wix$//;

	$self;
}

sub load {
	my $class = shift;
	my $file  = _STRING(shift)
		or Carp::croak("Did not provide a file name");
	unless ( -f $file ) {
		Carp::croak("Win32::Wix config file '$file' does not exist");
	}

	# Load the config file
	my $config = Config::Tiny->read( $file )
		or Carp::croak("Failed to load config file '$file'");

	# Hand off to the 'new' constructor
	$class->new( %$config, @_ );
}

sub candle_path {
	$_[0]->{candle_path};
}

sub light_path {
	$_[0]->{light_path};
}

sub wix_path {
	$_[0]->{wix_path};
}

sub base_path {
	$_[0]->{base_path};
}

sub wixobj_path {
	$_[0]->{base_path} . '.winobj';
}

sub msi_path {
	$_[0]->{msi_path} . '.msi';
}

sub msm_path {
	$_[0]->{msm_path} . '.msm';
}





#####################################################################
# Main Methods

sub build_wixobj {
	my $self = shift;

	# The wixobj file should not exist
	-f $self->wixobj_path
		or File::Remove::remove( $self->wixobj_path )
		or Carp::croak( "Failed to delete "
			. $self->wixobj_path );

	$self->_build_wixobj;
}

sub _build_wixobj {
	my $self = shift;

	# Build and execute the call to candle.exe
	my $stdin = '';
	my $cmd = [
		$self->candle_path,
		'-nologo',
		$self->wix_path,
		];
	IPC::Run3::run3( $cmd, \undef, \$stdin, \undef );

	# Check the result
	if ( $stdin =~ /\S/s ) {
		Carp::croak("candle.exe returned an error");
	}
	unless ( -f $self->winobj_path ) {
		Carp::croak("Failed to generate the .wixobj file");
	}

	1;
}

sub build_msi {
	my $self = shift;

	# Auto-build the wixobj if needed
	unless ( -f $self->winobj_path ) {
		$self->build_winobj;
	}

	# The wixobj file should not exist
	-f $self->msi_path
		or File::Remove::remove( $self->msi_path )
		or Carp::croak( "Failed to delete "
			. $self->msi_path );

	# Hand off to the main method
	$self->_build_msi;
}

sub _build_msi {
	my $self = shift;

	# Build and execute the call to candle.exe
	my $stdin = '';
	my $cmd = [
		$self->light_path,
		'-nologo',
		$self->wixobj_path,
		];
	IPC::Run3::run3( $cmd, \undef, \$stdin, \undef );

	# Check the result
	if ( $stdin =~ /\S/s ) {
		Carp::croak("light.exe returned an error");
	}
	unless ( -f $self->msi_path ) {
		Carp::croak("Failed to generate the .msi file");
	}

	1;
}

sub build_msm {
	my $self = shift;

	# Auto-build the wixobj if needed
	unless ( -f $self->winobj_path ) {
		$self->build_winobj;
	}

	# The wixobj file should not exist
	-f $self->msm_path
		or File::Remove::remove( $self->msm_path )
		or Carp::croak( "Failed to delete "
			. $self->msm_path );

	$self->_build_msm;
}

sub _build_msm {
	my $self = shift;

	# Build and execute the call to candle.exe
	my $stdin = '';
	my $cmd = [
		$self->light_path,
		'-nologo',
		$self->wixobj_path,
		];
	IPC::Run3::run3( $cmd, \undef, \$stdin, \undef );

	# Check the result
	if ( $stdin =~ /\S/s ) {
		Carp::croak("light.exe returned an error");
	}
	unless ( -f $self->msm_path ) {
		Carp::croak("Failed to generate the .msm file");
	}

	1;
}

1;
