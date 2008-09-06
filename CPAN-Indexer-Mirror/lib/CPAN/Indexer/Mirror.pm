package CPAN::Indexer::Mirror;

=pod

=head1 NAME

CPAN::Indexer::Mirror - Creates the mirror.yml and mirror.json files

=head1 DESCRIPTION

This module is used to implement a small piece of functionality inside the
CPAN/PAUSE indexer which generates the mirror.yml and mirror.json files.

These files are used to allow CPAN clients to implement mirror validation
and automated selection.

=cut

use 5.006;
use strict;
use File::Spec              ();
use File::Remove            ();
use YAML::Tiny              ();
use JSON                    ();
use Parse::CPAN::MirroredBy ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessor Methods

sub new {
	my $class = shift;
	return bless { @_ }, $class;
}

sub root {
	$_[0]->{root};
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
	my $self    = shift;

	# Generate the data structure for the files
	my @mirrors = $self->parser->parse_file( $self->mirrored_by );
	my $data    = {
		name      => "Comprehensive Perl Archive Network",
		url       => "http://www.cpan.org/",
		timestamp => $self->zulu,
		mirrors   => \@mirrors,
	};

	# Write the mirror.yml file
	if ( -f $self->mirror_yml ) {
		File::Remove::remove( $self->mirror_yml );
	}
	YAML::Tiny::DumpFile( $self->mirror_yml, $data );

	# Write the mirror.json file
	if ( -f $self->mirror_json ) {
		File::Remove::remove( $self->mirror_json );
	}
	open( FILE, '>' . $self->mirror_json ) or die "open: $!";
	print FILE JSON->new->pretty->encode( $data )  or die "print: $!";
	close( FILE )                          or die "close: $!";

	return 1;
}

sub parser {
	my $parser = Parse::CPAN::MirroredBy->new;
	$parser->add_map(  sub { $_[0]->{dst_http} } );
	$parser->add_grep( sub { defined $_[0] and $_[0] !~ /\s/ } );
	return $parser;
}

sub zulu {
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
