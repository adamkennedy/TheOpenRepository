package Module::Changes::ADAMK;

=pod

=head1 NAME

Module::Changes::ADAMK - Parse a traditional Changes file (as ADAMK interpretes it)

=head1 DESCRIPTION

This module was written for parsing ADAMK's Changes files (which are a pretty
traditional format that might be of us to others).

=cut

use 5.005;
use strict;
use Carp 'croak';
use DateTime                  0.4501 ();
use DateTime::Format::DateParse 0.04 (); 

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Module::Changes::ADAMK::Release ();
use Module::Changes::ADAMK::Change  ();

use Object::Tiny 1.03 qw{
	header
	dist_name
	module_name
};





#####################################################################
# Constructor and Accessors

sub read {
	my $class = shift;

	# Check the file
	my $file = shift or croak('You did not specify a file name');
	croak("File '$file' does not exist")              unless -e $file;
	croak("'$file' is a directory, not a file")       unless -f _;
	croak("Insufficient permissions to read '$file'") unless -r _;

	# Slurp in the file
	local $/ = undef;
	open CFG, $file or croak("Failed to open file '$file': $!");
	my $contents = <CFG>;
	close CFG;

	$class->read_string( $contents );
}

sub read_string {
	my $class = shift;
	my $self  = $class->new;

	# Normalize newlines
	my $string = shift;
	return undef unless defined $string;
	$string =~ s/(?:\015{1,2}\012|\015|\012)/\n/gs;

	# Split into paragraphs
	my @paragraphs = split /\n{2,}/, $string;

	# The first paragraph contains the name of the module, which
	# should be the last word.
	$self->{header} = shift @paragraphs;
	my @header_words = $self->{header} =~ /([\w:-]+)/g;
	unless ( @header_words ) {
		croak("Failed to find any words in the header");
	}
	my $name = $header_words[-1];
	$self->{dist_name}   = $name;
	$self->{module_name} = $name;
	if ( $name =~ /-/ ) {
		$self->{module_name} =~ s/-/::/g;
	} elsif ( $name =~ /::/ ) {
		$self->{dist_name} =~ s/::/-/g;
	}

	# Parse each paragraph into a release
	my @releases = ();
	foreach my $paragraph ( @paragraphs ) {
		push @releases, Module::Changes::ADAMK::Release->new($paragraph);
		
	}
	$self->{releases} = \@releases;

	return $self;
}

sub releases {
	return @{$_[0]->{releases}};
}





#####################################################################
# Main Methods

sub current_release {
	$_[0]->{releases}->[0];
}

sub current_version {
	$_[0]->current_release->version;
}

1;

=pod

=head1 SUPPORT

No support is available for this module

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
