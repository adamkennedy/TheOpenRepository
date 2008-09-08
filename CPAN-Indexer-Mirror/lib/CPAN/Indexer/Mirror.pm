package CPAN::Indexer::Mirror;

=pod

=head1 NAME

CPAN::Indexer::Mirror - Creates the mirror.yml and mirror.json files

=head1 SYNOPSIS

  use CPAN::Indexer::Mirror ();
  
  CPAN::Indexer::Mirror->new(
      root => '/cpan/root/directory',
  )->run;

=head1 DESCRIPTION

This module is used to implement a small piece of functionality inside the
CPAN/PAUSE indexer which generates the mirror.yml and mirror.json files.

These files are used to allow CPAN clients (via the L<Mirror::YAML> or
L<Mirror::JSON> modules) to implement mirror validation and automated
selection.

=head1 METHODS

Anyone who needs to know more detail than the SYNOPSIS should read the
(fairly straight forward) code.

=cut

use 5.006;
use strict;
use File::Spec              ();
use File::Remove            ();
use YAML::Tiny              ();
use JSON                    ();
use URI                     ();
use URI::http               ();
use Parse::CPAN::MirroredBy ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.03';
}





#####################################################################
# Constructor and Accessor Methods

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Apply defaults
	$self->{name} ||= 'Comprehensive Perl Archive Network';
	$self->{master}  ||= 'http://www.cpan.org/';

	return $self;
}

sub root {
	$_[0]->{root};
}

sub name {
	$_[0]->{name};
}

sub master {
	$_[0]->{master};
}

sub timestamp {
	$_[0]->{timestamp} || $_[0]->now;
}

sub mirrored_by {
	File::Spec->catfile( $_[0]->root, 'MIRRORED.BY' );
}

sub mirror_yml {
	File::Spec->catfile( $_[0]->root, 'mirror.yml' );
}

sub mirror_json {
	File::Spec->catfile( $_[0]->root, 'mirror.json' );
}





#####################################################################
# Process Methods

sub run {
	my $self = ref $_[0] ? shift : shift->new(@_);

	# Generate the data structure for the files
	my @mirrors = $self->parser->parse_file( $self->mirrored_by );
	my $data    = {
		version   => '1.0',
		name      => $self->name,
		master    => $self->master,
		timestamp => $self->timestamp,
		mirrors   => \@mirrors,
	};

	# Write the mirror.yml file
	my $yml = $self->mirror_yml;
	File::Remove::remove( $yml ) if -e $yml;
	YAML::Tiny::DumpFile( $yml, $data );

	# Write the mirror.json file
	my $json = $self->mirror_json;
	File::Remove::remove( $json ) if -e $json;
	SCOPE: {
		local $!;
		local *FILE;
		open( FILE, '>', $json )                    or die "open: $!";
		print FILE JSON->new->pretty->encode($data) or die "print: $!";
		close( FILE )                               or die "close: $!";
	}

	return 1;
}

sub parser {
	my $parser = Parse::CPAN::MirroredBy->new;
	$parser->add_map(  sub { $_[0]->{dst_http} } );
	$parser->add_grep( sub {
		defined $_[0]
		and
		$_[0] =~ /\/$/
	} );
	$parser->add_map(  sub { URI->new( $_[0], 'http' )->canonical->as_string } );
	return $parser;
}

sub now {
	my @t = gmtime time;
	return sprintf( "%04u-%02u-%02uT%02u:%02u:%02uZ",
		$t[5] + 1900,
		$t[4] + 1,
		$t[3],
		$t[2],
		$t[1],
		$t[0],
	);
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Indexer-Mirror>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Parse::CPAN::Authors>, L<Parse::CPAN::Packages>,
L<Parse::CPAN::Modlist>, L<Parse::CPAN::Meta>,
L<Parse::CPAN::MirroredBy>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
