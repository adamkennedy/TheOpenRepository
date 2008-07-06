package Unix::Remote;

# A general remote operation abstraction for Unix hosts

use 5.005;
use strict;
use Carp              'croak';
use IO::File          ();
use File::Spec        ();
use File::Spec::Unix  ();
use File::Temp        ();
use File::Slurp       ();
use Params::Util      qw{ _STRING _IDENTIFIER _CLASS _ARRAY0 _INSTANCE };
use Time::HiRes       ();
use Validate::Net     ();
use Net::Ping         ();
use Net::SSH          ();
use Net::SCP          ();
use ExtUtils::MM_Unix ();

use vars qw{$VERSION %REMOTE};
BEGIN {
	$VERSION = '0.01';
	%REMOTE  = (
		bin_sh   => '/bin/sh',
		bin_true => '/bin/true',
		bin_echo => '/bin/echo',
		perl_bin => '/use/bin',
		perl_exe => '/usr/bin/perl',
	);
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Apply defaults
	$self->{trace}       = !! $self->{trace};
	$self->{interactive} = !! $self->{interactive};

	# Check params
	unless ( _IDENTIFIER($self->name) ) {
		croak("Missing or invalid name param");
	}
	unless ( _HOST($self->address) ) {
		croak("Missing or invalid address param");
	}
	unless ( _IDENTIFIER($self->username) ) {
		croak("Missing or invalid username param");
	}	

	# Clear result variables
	$self->{ping_time}  = undef;
	$self->{ping_last}  = undef;
	$self->{scp_handle} = undef;

	return $self;
}

sub name {
	$_[0]->{name};
}

sub address {
	$_[0]->{address};
}

sub username {
	$_[0]->{username};
}

sub ping_time {
	$_[0]->{ping_time};
}

sub ping_last {
	$_[0]->{ping_last};
}

sub trace {
	$_[0]->{trace};
}

sub interactive {
	$_[0]->{interactive};
}





#####################################################################
# Generic Functionality Methods

### Network Operations ###

sub ping {
	shift->ssh_ping(@_);
}

# Ping the host's ssh port
sub ssh_ping {
	my $self   = shift;
	my $ping   = Net::Ping->new('tcp');

	# Because the network can be a little unreliable at first
	# try to connect to tcp ping the boxes up to 5 times.
	foreach ( 1 .. 10 ) {
		my $before = Time::HiRes::time();
		my $rv     = $ping->ping($self->address, 22) or next;
		my $after  = Time::HiRes::time();
		$self->{ping_time} = sprintf( "%0.2f", $after - $before );
		$self->{ping_last} = sprintf( "%0.2f", $before          );
		return $rv;
	}

	# Failed to ping the box
	$self->{ping_time} = undef;
	$self->{ping_last} = undef;

	return '';
}

### Raw SSH/SCP Operations ###

# Check SSH command capability by getting a value from echo
sub ssh_ok {
	my $self = shift;

	# Execute the command
	my $echo = $self->file_path('bin_echo');
	my @rv   = $self->ssh_cmd(
		command => $echo,
		args    => [ 'foo' ],
	);

	# Analyze the results
	return !! (
		scalar(@rv) == 1
		and
		defined($rv[0])
		and
		$rv[0] eq "foo\n"
	);
}

# Call an SSH command in batch mode
sub ssh_cmd {
	my $self   = shift;
	my %params = @_;
	unless ( $params{command} ) {
		croak("The command param was not provided to ssh_cmd");
	}
	if ( $params{args} and ! _ARRAY0($params{args}) ) {
		croak("The args param to ssh_cmd must be an ARRAY reference");
	}

	# Hand off to Net::SSH
	my $stdout = Net::SSH::ssh_cmd( {
		user => $self->username,
		host => $self->address,
		%params,
	} );

	return $stdout;
}

# A simplified version of ssh_cmd
sub ssh_run {
	my $self    = shift;
	my $command = shift;
	my @args    = @_;
	return $self->ssh_cmd(
		command => $command,
		args    => \@args,
	);
}

# Execute a Perl script via STDIN and capture the results
sub ssh_perl {
	my $self = shift;
	my $perl = $self->file_path('perl_exe');
	my $code = _STRING(shift)
		or croak("Did not pass a string to ssh_perl");

	# Run the command and return the results
	return $self->ssh_cmd(
		command      => $perl,
		stdin_string => $code,
	);
}

# Check SSH capability by getting the size of a file
# we know must exist on every screen.
sub scp_ok {
	my $self = shift;
	my $path = $self->file_path('bin_sh');
	return $self->file_exists( $path );
}

# Get an scp handle for the screen
sub scp_handle {
	my $self = shift;
	$self->{scp_handle} ||= Net::SCP->new( {
		host        => $self->address,
		user        => $self->username,
		interactive => 0,
		cwd         => '/Users/localvision',
		} )
		or croak("Failed to create SCP handle");
	return $self->{scp_handle};
}

# Get a file from the remote machine
# $self->get( REMOTE_FILE [, LOCAL_FILE ] )
sub scp_get {
	my $self  = shift;
	my $from  = _REMOTE(shift);
	my $to    = _LOCAL(shift);

	# Get the file
	$self->scp_handle->get($from => $to);

	# Return based on whether the file was actually created
	return !! -f $to;
}

# Get a file from the remote machine to a local temp file
sub scp_gettmp {
	my $self = shift;
	my $from = _REMOTE(shift);
	my $to   = File::Temp::tmpnam();

	# Get the file and return the filename on success
	$self->scp_get( $from => $to ) and $to;
}

# Put a file to the remote machine
# $self->put( LOCAL_FILE [, REMOTE_FILE ] )
sub scp_put {
	my $self  = shift;
	my $from  = _LOCAL(shift);
	my $to    = _LOCAL(shift);

	# Put the file
	$self->scp_handle->put($from => $to);

	# Return based on the file actually existing
	return !! $self->scp_handle->size($to);
}

### File Manipulation ###

sub file_path {
	my $self = shift;
	my $path = $REMOTE{$_[0]};
	unless ( _STRING($path) ) {
		croak("Failed to find remote file path '$_[0]'");
	}
	return $path;
}

# Checks to see if a file exists
sub file_exists {
	my $self = shift;
	my $path = _REMOTE(shift);
	return !! $self->scp_handle->size($path);
}

# Get the size of a file
sub file_size {
	my $self = shift;
	my $path = _REMOTE(shift);
	return $self->scp_handle->size($path);
}

# Get a read-onlie filehandle to the remote file
sub file_handle_ro {
	my $self = shift;

	# Fetch the file from the server to a temp file
	my $file = $self->scp_gettmp($_[0])
		or croak("Failed to fetch $_[0]");

	# Open the file
	my $io = IO::File->new( $file, 'r' );
	unless ( _INSTANCE($io, 'IO::File') ) {
		croak("Failed to create handle for $_[0] via $file");
	}

	return $io;	
}

# Slurp a remote file
sub file_slurp {
	my $self = shift;
	my $file = $self->scp_gettmp($_[0])
		or croak("Failed to fetch $_[0]");

	# Slurp (scalar or list context as needed, see File::Slurp docs)
	return File::Slurp::read_file( $file );
}

### Perl Functionality ###

# Check Perl command capability by print a value
sub perl_ok {
	my $self = shift;
	my $out  = $self->ssh_perl('print "bar\n";');
	return !!( defined $out and $out eq "bar\n");
}

# Does the Perl we need exist?
sub perl_exists {
	my $self = shift;
	my $perl = $self->file_path('perl_exe');
	return $self->file_exists($perl);
}

# Get the version of Perl
sub perl_version {
	my $self = shift;
	my $out  = $self->ssh_perl( 'print "$]\n";' );
	unless ( $out and $out =~ /^([\d\.]+)/s ) {
		croak("Failed to determine version for remote perl");
	}
	return "$1";
}

# Get the architecture
sub perl_arch {
	my $self = shift;
	my $out  = $self->ssh_perl( 'print "$^O\n";' );
	unless ( $out and $out =~ /^(\w+)/s ) {
		croak("Failed to determine architecture for remote perl");
	}
	return "$1";
}

# Get the remote path for a perl script
sub script_path {
	my $self   = shift;
	my $script = _IDENTIFIER(shift)
		or croak("Did not provide an identifier to script_path");

	# Join it to the perl bin path
	return File::Spec::Unix->catfile(
		$self->file_path('perl_bin'), $script,
		);
}

# Does a perl script we need exist?
sub script_exists {
	my $self = shift;
	my $path = $self->script_path(shift);
	return $self->file_exists($path);
}

# Get the version of a script
sub script_version {
	my $self = shift;
	my $path = $self->script_path(shift);
	my $file = $self->scp_gettmp($path) or return undef;
	return ExtUtils::MM_Unix->parse_version($file) || 0;
}

# Convenience shortcut
sub module_subpath {
	my $self   = shift;
	my $module = _CLASS(shift) or croak("Missing or invalid module name");
	return join '/', split /::/, $module . '.pm';
}

# Get the path for a module
sub module_exists {
	my $self    = shift;
	my $module  = _CLASS(shift) or croak("Missing or invalid module name");

	# Try to load the module
	my $code = qq{
		if ( eval { require $module } ) {
			print "1\n";
		} else {
			print "0\n";
		}
	};
	my $rv = $self->ssh_perl( $code );
	chomp $rv if $rv;
	return !! ( $rv and $rv eq '1' );
}

# Get the installed version of a module
sub module_version {
	my $self    = shift;
	my $module  = _CLASS(shift) or croak("Missing or invalid module name");

	# Try to load the module
	my $code = qq{
		if ( eval { require $module } ) {
			my \$version = $module->VERSION;
			if ( ! defined \$version ) {
				\$version = 'undef';
			} else {
				\$version = "'\$version'";
			}
			print "\$version\n";
		} else {
			print "\n";
		}
	};
	my $rv = $self->ssh_perl( $code );
	chomp $rv if defined $rv;
	unless ( _STRING($rv) ) {
		croak("Failed to load $module");
	}
	if ( $rv eq 'undef' ) {
		return undef;
	}
	unless ( $rv =~ /^'(.*)'$/ ) {
		croak("Illegal or unexpected module version");
	}
	return "$1";
}





#####################################################################
# Utility Functions

sub _HOST {
	(_STRING($_[0]) and Validate::Net->host($_[0])) ? $_[0] : undef;
}

sub _LOCAL {
	_STRING($_[0]) ? $_[0] : croak("Invalid local file name");
	
}

sub _REMOTE {
	_STRING($_[0]) ? $_[0] : croak("Invalid remote file name");
}

1;
