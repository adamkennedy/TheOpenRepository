package ADAMK::Distribution::Checkout;

use 5.008;
use strict;
use warnings;
use Carp                   ();
use File::Spec             ();
use ADAMK::Role::SVN       ();
use File::Find::Rule       ();
use File::Find::Rule::Perl ();
use Module::Changes::ADAMK ();
use ADAMK::Repository      ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.09';
	@ISA     = qw{
		ADAMK::Role::File
		ADAMK::Role::SVN
		ADAMK::Role::Changes
		ADAMK::Role::Make
	};
}

use Class::XSAccessor
	getters => {
		name         => 'name',
		distribution => 'distribution',
	};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

sub repository {
	$_[0]->distribution->repository;
}

sub releases {
	$_[0]->distribution->releases;
}

sub trace {
	shift->repository->trace(@_);
}





#####################################################################
# High Level Methods

sub update_current_release_datetime {
	my $self    = shift;
	my $changes = $self->changes;
	my $release = $changes->current;
	$release->set_datetime_now;
	my $version = $release->version;
	my $date    = $release->date;
	$self->trace("Set version $version release date to $date\n");
	$changes->save;
	return $date;
}

# Change the version in all Perl files from the previous
# release to the current release. Return the number of files
# that were successfully changed.
sub update_current_perl_versions {
	my $self     = shift;
	my @releases = map { $_->version } ($self->changes->releases)[0..1];
	unless ( @releases == 2 ) {
		die("Need at least two releases to update versions");
	}

	# Locate the Perl files in the distribution
	my @files = File::Find::Rule->perl_file->in( $self->path );
	$self->trace("Found " . scalar(@files) . " file(s)\n");

	# Check all the files
	my $count = 0;
	my $to    = "'$releases[0]'";
	my $from  = "'$releases[1]'";
	foreach my $file ( @files ) {
		next unless -w $file;

		# Parse the file
		my $document = PPI::Document->new( $file );
		unless ( $document ) {
			die("Failed to parse '$file'");
		}

		# Locate the version
		my $elements = $document->find( sub {
			$_[1]->isa('PPI::Token::Quote')               or return '';
			$_[1]->content eq $from                       or return '';
			my $equals = $_[1]->sprevious_sibling         or return '';
			$equals->isa('PPI::Token::Operator')          or return '';
			$equals->content eq '='                       or return '';
			my $version = $equals->sprevious_sibling      or return '';
			$version->isa('PPI::Token::Symbol')           or return '';
			$version->content =~ m/^\$(?:\w+::)*VERSION$/ or return '';
			return 1;
		} );
		next unless $elements;
		if ( @$elements > 1 ) {
			die("Found more than one version in '$file'");
		}
		$elements->[0]->{content} = $to;
		unless ( $document->save($file) ) {
			die("PPI::Document save failed for '$file'");
		}

		$self->trace("Changed $file\n");
		$count++;
	}

	return $count;
}

1;
