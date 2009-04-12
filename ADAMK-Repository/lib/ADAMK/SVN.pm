package ADAMK::SVN;

use 5.008;
use strict;
use warnings;
use IPC::Run3    ();
use File::Spec   ();
use File::pushd  ();
use Params::Util qw{ _STRING };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.06';
}

use Object::Tiny;

sub trace {
	$_[0]->{trace}->( @_[1..$#_] ) if $_[0]->{trace};
}





#####################################################################
# SVN Methods

sub svn_command {
	my $self   = shift;
	my $root   = File::pushd::pushd( $self->root );
	$self->trace("> " . join( ' ', 'svn', @_ ) . "\n");
	my $stdout = '';
	IPC::Run3::run3(
		[ 'svn', @_ ],
		\undef,
		\$stdout,
		\undef,
	);
	return split /\n/, $stdout;
}

sub svn_info {
	my $self = shift;
	my @info = $self->svn_command( 'info', @_ );
	my %hash = map {
		/^([^:]+)\s*:\s*(.*)$/;
		my $key   = "$1";
		my $value = "$2";
		$key =~ s/\s+//g;
		( $key, $value );
	} grep { length $_ } @info;
	return \%hash;
}

sub svn_root {
	my $self = shift;
	my $root  = shift;
	unless ( defined _STRING($root) ) {
		return undef;
	}
	unless ( -d $root ) {
		return undef;
	}
	unless ( -d File::Spec->catdir($root, '.svn') ) {
		return undef;
	}
	return $root;
}

sub svn_commit {
	my $self = shift;
	my @rv   = $self->svn_command(
		'commit', @_,
	);
	unless ( $rv[-1] =~ qr/commit/ ) {
		die('Failed to commit');
	}
	return 1;
}

1;
