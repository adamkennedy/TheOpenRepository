package Test::ScanAPI;

=pod

=head1 NAME

Test::ScanAPI - Scan source code to check that classes and methods exist

=head1 DESCRIPTION

This is a companion module to L<Test::ClassAPI>, and like its brother is
intended primarily for use on very large codebases.

L<Test::ScanAPI> reads through your code and looks for the names of 
classes, and calls to various methods within them. After scanning all
the code and building up a list of expected code elements, it will check
for the existance of all those elements.

=cut

use 5.005;
use strict;
use File::Find::Rule       ();
use File::Find::Rule::Perl ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params and apply defaults
	unless ( defined $self->dir and -d $self->dir ) {
		croak("Missing or invalid 'dir' param");
	}
	unless ( defined $self->filter ) {
		$self->{filter} = File::Find::Rule->

}

sub dir {
	$_[0]->{dir};
}

sub filter {
	$_[0]->{filter}
}

sub namespace {
	$_[0]->{namespace};
}

1;

=pod

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-ScanAPI>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
