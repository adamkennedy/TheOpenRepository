package CGI::Install;

=pod

=head1 NAME

CGI::Install - Installer for CGI applications

=head1 DESCRIPTION

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp         ();
use File::Spec   ();
use File::Copy   ();
use File::chmod  ();
use File::Which  ();
use File::Remove ();
use Scalar::Util ();
use Params::Util qw{ _STRING _CLASS _INSTANCE };
use Term::Prompt ();
use URI::ToDisk  ();
use LWP::Simple  ();
use CGI::Capture ();

use vars qw{$VERSION $CGICAPTURE};
BEGIN {
	$VERSION = '0.01';

	# Locate the cgicapture application
	$CGICAPTURE ||= File::Which::which('cgicapture');
	unless ( $CGICAPTURE and -f $CGICAPTURE ) {
		Carp::croak("Failed to locate the 'cgicapture' application");
	}
}

use Object::Tiny qw{
	interactive
	install_cgi
	install_static
	cgi_path
	cgi_uri
	cgi_capture
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

	# By default, install CGI but not static
	unless ( defined $self->install_cgi ) {
		$self->{install_cgi} = 1;
	}
	unless ( defined $self->install_static ) {
		$self->{install_static} = 1;
	}
	
	# Auto-detect interactive mode if needed
	unless ( defined $self->interactive ) {
		$self->{interactive} = $self->_is_interactive;
	}

	# Normalize the boolean flags
	$self->{interactive}    = !! $self->{interactive};
	$self->{install_cgi}    = !! $self->{install_cgi};
	$self->{install_static} = !! $self->{install_static};

	return $self;
}

sub prepare {
	my $self = shift;

	# Check the cgi params if installing CGI
	if ( $self->install_cgi ) {
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

		# Validate the CGI settings
		unless ( $self->validate_cgi($self->cgi_map->catfile('test')) ) {
			return $self->prepare_error("CGI mapping failed testing");
		}
	} else {
		# CGI stuff not needed
		delete $self->{cgi_path};
		delete $self->{cgi_uri};
	}

	# Check the static params if installing static
	if ( $self->install_static ) {
		# Get and check the base cgi path
		if ( $self->interactive and ! defined $self->static_path ) {
			$self->{static_path} = Term::Prompt(
				'x', 'Static Directory:', '',
				File::Spec->rel2abs( File::Spec->curdir ),
			);
		}
		my $static_path = $self->static_path;
		unless ( defined $static_path ) {
			return $self->prepare_error("No static_path provided");
		}
		unless ( -d $static_path ) {	
			return $self->prepare_error("The static_path '$static_path' does not exist");
		}
		unless ( -w $static_path ) {
			return $self->prepare_error("The static_path '$static_path' is not writable");
		}

		# Get and check the cgi_uri
		if ( $self->interactive and ! defined $self->static_uri ) {
			$self->{static_uri} = Term::Prompt(
				'x', 'Static URI:', '', '',
			);
		}
		unless ( defined _STRING($self->static_uri) ) {
			return $self->prepare_error("No static_path provided");
		}

		# Validate the CGI settings
		$self->validate_static_dir(
			$self->static_map->catfile('cgicapture.txt')
			) or return $self->prepare_error("Static mapping failed testing");
	} else {
		# Static stuff not needed
		delete $self->{static_path};
		delete $self->{static_uri};
	}

	return 1;
}





#####################################################################
# Accessor-Derived Methods

sub cgi_map {
	$_[0]->install_cgi or return undef;
	URI::ToDisk->new( $_[0]->cgi_path => $_[0]->cgi_uri );
}

sub static_map {
	$_[0]->install_static or return undef;
	URI::ToDisk->new( $_[0]->static_path => $_[0]->static_uri );
}





#####################################################################
# Manipulation

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
# Functional Methods

sub validate_cgi_dir {
	my $self = shift;
	my $cgi  = _INSTANCE(shift, 'URI::ToDisk')
		or Carp::croak("Did not pass a URI::ToDisk object to valid_cgi");

	# Copy the cgicapture application to the CGI path
	unless ( File::Copy::copy( $CGICAPTURE, $cgi->path ) ) {
		return undef;
		# Carp::croak("Failed to copy cgicapture into place");
	}
	unless ( File::chmod::chmod('a+rx', $cgi->path) ) {
		return undef;
		# Carp::croak("Failed to set executable permissions");
	}

	# Call the URI
	my $www = LWP::Simple::get( $cgi->URI );
	unless ( defined $www ) {
		return undef;
		# Carp::croak("Nothing returned from the cgicapture web request");
	}
	if ( $www =~ /^\#\!\/usr\/bin\/perl/ ) {
		return undef;
		# Carp::croak("URI is not a CGI path");
	}
	unless ( $www =~ /^---\nARGV\:/ ) {
		return undef;
		# Carp::croak("Unknown value returned from URI");
	}

	# Superficially ok, convert to capture object
	$self->{cgi_capture} = CGI::Capture->from_yaml_string($www);
	unless ( _INSTANCE($self->{cgi_capture}, 'CGI::Capture') ) {
		return undef;
		# Carp::croak("Failed to create capture object");
	}

	return 1;
}

sub validate_static_dir {
	my $self = shift;
	my $dir  = _INSTANCE(shift, 'URI::ToDisk')
		or Carp::croak("Did not pass a URI::ToDisk object to valid_static");
	my $file = $dir->catfile('cgiinstall.txt');

	# Write a test file to the directory
	my $test_string = int(rand(100000000+1000));
	open( FILE, '>' . $file->path ) or die "open: $!";
	print FILE $test_string           or die "print: $!";
	close FILE                        or die "close: $!";

	# Call the URI
	my $www = LWP::Simple::get( $file->URI );

	# Clean up the file now, before we check for errors
	File::Remove::remove( $file->path );

	# Continue and check for errors
	unless ( defined $www ) {
		return undef;
		# Carp::croak("Nothing returned from the cgicapture web request");
	}

	# Check the result
	unless ( $www eq $test_string ) {
		return undef;
		# Carp::croak("Unknown value returned from URI");
	}

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

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Install>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>cpan@ali.asE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<CGI::Capture>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
