package ADAMK::Role::SVN;

use 5.008;
use strict;
use warnings;
use IPC::Run3    ();
use File::Spec   ();
use File::pushd  ();
use Params::Util qw{ _STRING };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.08';
}





#####################################################################
# SVN Methods

sub svn_command {
	my $self   = shift;
	my $root   = File::pushd::pushd( $self->root );
	$self->trace("> " . join( ' ', map { /\s/ ? "'$_'" : $_ } 'svn', @_ ) . "\n");
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
	unless ( @rv ) {
		# Nothing changed
		$self->trace("Nothing changed in commit.\n");
		return 0;
	}
	unless ( $rv[-1] =~ qr/^Committed revision \d+\.$/ ) {
		die("Commit failed: $rv[-1]");
	}
	$self->trace("$rv[-1]\n");
	return 1;
}

1;
