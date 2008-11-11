package ADAMK::Repository;

# Implements a basic convenience model of ADAMK's repository.

use 5.008;
use strict;
use warnings;
use Carp                  'croak';
use File::Spec            ();
use File::pushd           'pushd';
use File::Find::Rule      ();
use File::Find::Rule::VCS ();
use Params::Util          qw{ _STRING _CODE };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	root
};

# Preroll file find rules
my $RELEASES = File::Find::Rule->name('*.tar.gz', '*.zip')->file->relative;





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Check params
	unless ( -d $self->svn_dir($self->root) ) {
		croak("Missing or invalid SVN root directory");
	}
	if ( $self->{trace} and not _CODE($self->{trace}) ) {
		$self->{trace} = sub { print @_ };
	}

	return $self;
}

sub dir {
	File::Spec->catdir( shift->root, @_ );
}

sub file {
	File::Spec->catfile( shift->root, @_ );
}

sub trace {
	$_[0]->{trace}->( @_[1..$#_] ) if $_[0]->{trace};
}





#####################################################################
# Releases

sub release_dir {
	$_[0]->dir('releases');
}
	
sub release_files {
	$RELEASES->in( $_[0]->release_dir );
}





#####################################################################
# Simple SVN Interfaces

sub svn_dir {
	my $self = shift;
	my $dir  = shift;
	unless ( defined _STRING($dir) ) {
		return undef;
	}
	unless ( -d $dir ) {
		return undef;
	}
	unless ( -d File::Spec->catdir($dir, '.svn') ) {
		return undef;
	}
	return $dir;
}

sub svn_command {
	my $self = shift;
	my $root = pushd( $self->root );
	my $cmd  = join( ' ', 'svn', @_ );
	$self->trace("> $cmd\n");
	my @rv   = `$cmd`;
	chomp(@rv);
	return @rv;
}

sub svn_info {
	my $self = shift;
	my $dir  = $self->svn_dir(shift);
	my @info = $self->svn_command('info');
	my %hash = map {
		/^([^:]+)\s*:\s*(.*)$/;
		my $key   = "$1";
		my $value = "$2";
		$key =~ s/\s+//g;
		( $key, $value );
	} grep { length $_ } @info;
	$hash{Directory} = $dir;
	return \%hash;
}

1;
