package ADAMK::Role::SVN;

use 5.008;
use strict;
use warnings;
use IPC::Run3         ();
use XML::Tiny         ();
use File::Spec        ();
use File::pushd       ();
use Params::Util      ();
use IO::ScalarArray   ();
use ADAMK::Cache      ();
use ADAMK::Repository ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.11';
}





#####################################################################
# SVN Methods

sub svn_dir {
	my $self = shift;
	my $dir  = shift;
	unless ( defined Params::Util::_STRING($dir) ) {
		return undef;
	}
	unless ( -d File::Spec->catdir($dir, '.svn') ) {
		return undef;
	}
	return $dir;
}

sub svn_cache_command {
	my $self      = shift;
	my $directory = $self->directory;
	my $command   = join( ' ', map { /\s/ ? "'$_'" : $_ } 'svn', @_ );

	# Check for the cached version
	my @cached = ADAMK::Cache::Svn->select(
		'where directory = ? and command = ?',
		$directory, $command,
	);
	unless ( @cached ) {
		# Run the command
		my $root = File::pushd::pushd( $directory );
		$self->trace("> $command\n");
		my $stdout = '';
		IPC::Run3::run3(
			[ 'svn', @_ ],
			\undef,
			\$stdout,
			\undef,
		);

		# Save the result to the cache
		@cached = ADAMK::Cache::Svn->create(
			directory => $directory,
			command   => $command,
			stdout    => $stdout,
		);
	}

	return split /\n/, $cached[0]->stdout;
}

sub svn_command {
	my $self = shift;
	my $root = File::pushd::pushd( $self->directory );
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

sub svn_subdir {
	my $self = shift;
	my $dir  = File::Spec->catdir(@_);
	unless ( $self->svn_dir($self->directory, $dir) ) {
		return undef;
	}
	return $dir;
}

sub svn_file {
	my $self = shift;
	my $file = File::Spec->catfile(@_);
	my $path = $self->file($file);
	unless ( -f $path ) {
		return undef;
	}
	my ($v, $d, $f) = File::Spec->splitpath($path);
	my $svn = File::Spec->catpath(
		$v,
		File::Spec->catdir($d, '.svn', 'text-base'),
		"$f.svn-base",
	);
	unless ( -f $svn ) {
		return undef;
	}
	return $file;
}

sub svn_url {
	shift->svn_info->{URL};
}

sub svn_author {
	shift->svn_info->{LastChangedAuthor};
}

sub svn_revision {
	shift->svn_info->{LastChangedRev};
}

sub svn_date {
	shift->svn_info->{LastChangedDate};
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

sub svn_log {
	my $self  = shift;

	# Load the log tree
	my @lines = $self->svn_cache_command('log', '--xml', @_);
	my $input = IO::ScalarArray->new(\@lines);
	my $tree  = XML::Tiny::parsefile($input);

	# Parse the log tree
	my @entries = ();
	foreach my $hash ( reverse @{$tree->[0]->{content}} ) {
		my %entry = (
			revision => $hash->{attrib}->{revision},
			map {
				$_->{name} => $_->{content}->[0]->{content},
			} @{$hash->{content}}
		);
		$entry{message} = delete $entry{msg};
		push @entries, ADAMK::LogEntry->new( %entry );
	}

	return @entries;
}

1;
