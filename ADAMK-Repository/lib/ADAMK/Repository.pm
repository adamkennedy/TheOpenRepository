package ADAMK::Repository;

# Implements a basic convenience model of ADAMK's repository.

use 5.008;
use strict;
use warnings;
use Carp         'croak';
use File::pushd  'pushd';
use Params::Util '_STRING';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	root
};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Check params
	unless ( -d $self->svn_dir($self->root) ) {
		croak("Missing or invalid SVN root directory");
	}

	return $self;
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
