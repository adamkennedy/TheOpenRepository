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
use ADAMK::SVN::Info  ();
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

sub svn_command {
	my $self      = shift;
	my $options   = ref($_[-1]) ? pop(@_) : {};
	my $directory = $self->directory;
	my $command   = join( ' ', map { /\s/ ? "'$_'" : $_ } 'svn', @_ );

	# Check for the cached version
	if ( $options->{cache} ) {
		my @cached = ADAMK::Cache::Svn->select(
			'where directory = ? and command = ?',
			$directory, $command,
		);
		if ( @cached ) {
			$self->trace("- $directory: $command\n");
			return split /\n/, $cached[0]->stdout;		
		}
	}

	# Run the command
	my $root = File::pushd::pushd( $directory );
	my $char = $options->{cache} ? '+' : '>';
	$self->trace( "$char $directory: $command\n");
	my $stdout = '';
	IPC::Run3::run3(
		[ 'svn', @_ ],
		\undef,
		\$stdout,
		\undef,
	);

	# Save the result to the cache
	ADAMK::Cache::Svn->create(
		directory => $directory,
		command   => $command,
		stdout    => $stdout,
	) if $options->{cache};

	return split /\n/, $stdout;
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

sub svn_commit {
	my $self   = shift;
	my @stdout = $self->svn_command(
		'commit', @_,
	);
	unless ( @stdout ) {
		# Nothing changed
		$self->trace("Nothing changed in commit.\n");
		return 0;
	}
	unless ( $stdout[-1] =~ qr/^Committed revision \d+\.$/ ) {
		die("Commit failed: $stdout[-1]");
	}
	$self->trace("$stdout[-1]\n");
	return 1;
}

sub svn_log {
	my $self  = shift;

	# Load the log tree
	my @lines = $self->svn_command('log', '--xml', @_);
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

sub info {
	ADAMK::SVN::Info->new(
		shift->svn_command( 'info', @_ )
	);
}

1;
