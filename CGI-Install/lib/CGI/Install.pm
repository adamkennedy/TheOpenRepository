package CGI::Install;

use 5.005;
use strict;
use File::Spec   ();
use File::Copy   ();
use Scalar::Util ();
use Params::Util qw{ _STRING _CLASS };
use Term::Prompt ();
use URI::ToDisk  ();
use LWP::Simple  ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	interactive
	cgi_path
	cgi_uri
	static_path
	static_uri
	errstr
};





#####################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Create the arrays for scripts and libraries
	$self->{bin}   = [];
	$self->{class} = [];

	# Auto-detect interactive mode if needed
	unless ( defined $self->interfactive ) {
		$self->{interactive} = $self->_is_interactive;
	}

	return $self;
}

sub prepare {
	my $self = shift;

	# Get and check the base cgi path
	if ( $self->interactive and ! defined $self->cgi_path ) {
		$self->{cgi_path} = Term::Prompt(
			'x', 'CGI Directory:', '',
			File::Spec->rel2abs( File::Spec->curdir ),
		);
	}
	my $cgi_path = $self->cgi_path;
	unless ( defined $cgi_path ) {
		return $self->prepare_error("No cgi_path provided");
	}
	unless ( -d $cgi_path ) {	
		return $self->prepare_error("The cgi_path '$cgi_path' does not exist");
	}
	unless ( -w $cgi_path ) {
		return $self->prepare_error("The cgi_path '$cgi_path' is not writable");
	}

	# Get and check the cgi_uri
	if ( $self->interactive and ! defined $self->cgi_uri ) {
		$self->{cgi_uri} = Term::Prompt(
			'x', 'CGI URI:', '', '',
		);
	}
	unless ( defined _STRING($self->cgi_uri) ) {
		return $self->prepare_error("No cgi_path provided");
	}

	return 1;	
}





#####################################################################
# Accessor-Derived Methods

sub cgi_map {
	URI::ToDisk->new( $_[0]->cgi_path => $_[0]->cgi_uri );
}

sub static_map {
	URI::ToDisk->new( $_[0]->static_path => $_[0]->static_uri );
}





#####################################################################
# Adding 

sub add_bin {
	my $self = shift;
	my $bin  = _STRING(shift) or die "Invalid bin name";
	File::Which::which($bin)  or die "Failed to find '$bin'";
	push @{$self->{bin}}, $bin;
	return 1;
}

sub add_class {
	my $self  = shift;
	my $class = _CLASS(shift)     or die "Invalid class name";
	$self->_module_exists($class) or die "Failed to find '$class'";
	push @{$self->{class}}, $class;
	return 1;
}





#####################################################################
# Utility Methods

sub new_error {
	my $self = shift;
	$self->{errstr} = _STRING(shift) || 'Unknown error';
	return;
}

sub prepare_error {
	my $self = shift;
	return _STRING(shift) || 'Unknown error';
}

# Copied from IO::Interactive
sub _is_interactive {
	my $self = shift;

	# Default to default output handle
	my ($out_handle) = (@_, select);  

	# Not interactive if output is not to terminal...
	return 0 if not -t $out_handle;

	# If *ARGV is opened, we're interactive if...
	if ( Scalar::Util::openhandle *ARGV ) {
		# ...it's currently opened to the magic '-' file
		return -t *STDIN if defined $ARGV && $ARGV eq '-';

		# ...it's at end-of-file and the next file is the magic '-' file
		return @ARGV>0 && $ARGV[0] eq '-' && -t *STDIN if eof *ARGV;

		# ...it's directly attached to the terminal 
		return -t *ARGV;
	}

	# If *ARGV isn't opened, it will be interactive if *STDIN is attached 
	# to a terminal and either there are no files specified on the command line
	# or if there are files and the first is the magic '-' file
	return -t *STDIN && (@ARGV==0 || $ARGV[0] eq '-');
}

sub _module_exists {
	my @parts = split /::/, $_[0];
	my @found =
		grep { -f $_ }
		map  { catdir($_, @parts) . '.pm' }
		grep { -d $_ } @INC;
	return !! @found;
}

1;
