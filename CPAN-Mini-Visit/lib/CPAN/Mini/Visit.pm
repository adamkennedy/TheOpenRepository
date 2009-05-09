package CPAN::Mini::Visit;

=pod

=head1 NAME

CPAN::Mini::Visit - A generalised API version of David Golden's visitcpan

=head1 DESCRIPTION

To be completed

=cut

use 5.008;
use strict;
use warnings;
use Carp                  'croak';
use File::Spec       0.80 ();
use File::Temp       0.21 ();
use File::pushd      1.00 ();
use File::Find::Rule 0.27 ();
use Params::Util     0.36 qw{_STRING _CODELIKE};
use Archive::Extract 0.30 ();

our $VERSION = '0.01';

use Object::Tiny 1.06 qw{
	root
	authors
	callback
	acme
	author
};

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( defined _STRING($self->root) and -d $self->root ) {
		croak("Missing or invalid 'root' param");
	}
	unless ( _CODELIKE($self->callback) ) {
		croak("Missing or invalid 'callback' param");
	}

	# Derive the authors directory
	$self->{authors} = File::Spec->catdir( $self->root, 'authors', 'id' );
	unless ( -d $self->authors ) {
		croak("Authors directory '$self->{authors}' does not exist");
	}


	return $self;
}

sub run {
	my $self = shift;

	# Search for the files
	my $find  = File::Find::Rule->name('*.tar.gz')->file->relative;
	my @files = sort $find->in( $self->authors );
	unless ( $self->acme ) {
		@files = grep { ! /\bAcme\b/ } @files;
	}

	# Extract the archive
	foreach my $file ( @files ) {
		# Derive the main file properties
		my $path     = File::Spec->catfile( $self->authors, $file );
		my $distpath = $file;
		$distpath =~ s|^[A-Z]/[A-Z][A-Z]/|| or die "Bad distpath for $file";
		unless ( $distpath =~ /^([A-Z]+)/ ) {
			die "Bad author for $file";
		}
		my $author = "$1";
		if ( $self->author and $self->author ne $author ) {
			next;
		}

		# Extract the archive
		my $archive = Archive::Extract->new( archive => $path );
		my $tmpdir  = File::Temp->newdir;
		unless ( $archive->extract( to => $tmpdir ) ) {
			warn("Failed to extract '$path'");
			next;
		}

		# Change into the directory
		my $dir   = $archive->extract_path;
		my $pushd = File::pushd::pushd( $dir );

		# Invoke the callback
		$self->callback->( $distpath, $path, $dir );
	}

	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Mini-Visit>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
