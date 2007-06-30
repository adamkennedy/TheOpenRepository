package File::Find::Rule::Perl;

=pod

=head1 NAME

File::Find::Rule::Perl - Common rules for searching for Perl things

=head1 SYNOPSIS

  use File::Find::Rule       ();
  use File::Find::Rule::Perl ();
  
  # Find all Perl files smaller than 10k
  my @files = File::Find::Rule->perl_file
                              ->size('<10Ki')
                              ->in( $dir );

=head1 DESCRIPTION

I write a lot of things that muck with Perl files. And it always annoyed
me that finding "perl files" requires a moderately complex
L<File::Find::Rule> pattern.

B<File::Find::Rule::Perl> provides methods for finding various Perl-related
files.

=head1 METHODS

=cut

use 5.005;
use strict;
use UNIVERSAL;
use base 'File::Find::Rule';
use constant FFR => 'File::Find::Rule';

use vars qw{$VERSION @EXPORT};
BEGIN {
	$VERSION = '0.03';
	@EXPORT  = @File::Find::Rule::EXPORT;
}





#####################################################################
# File::Find::Rule Method Addition

=pod

=head2 perl_module

The C<perl_module> rule locates perl modules. That is, files that
are named C<*.pm>.

This rule is equivalent to C<-E<gt>>file-E<gt>name( '*.pm' )> and is
included primarily for completeness.

=cut

sub File::Find::Rule::perl_module {
	my $self = shift()->_force_object;
	$self->file->name( '*.pm' );
}

=pod

=head2 perl_test

The C<perl_test> rule locates perl test scripts. That is, files that
are named C<*.t>.

This rule is equivalent to C<-E<gt>>file-E<gt>name( '*.t' )> and is
included primarily for completeness.

=cut

sub File::Find::Rule::perl_test {
	my $self = shift()->_force_object;
	$self->file->name( '*.t' );
}

=pod

=head2 perl_installer

The C<perl_installer> rule locates perl distribution installers. That is,
it locates C<Makefile.PL> and C<Build.PL> files.

=cut

sub File::Find::Rule::perl_installer {
	my $self = shift()->_force_object;
	$self->file->name( 'Makefile.PL', 'Build.PL' );
}

=pod

=head2 perl_script

The C<perl_script> rule locates perl scripts.

This is any file that ends in F<.pl>, or any files without extensions
that have a perl "hash-bang" line.

=cut

sub File::Find::Rule::perl_script {
	my $self = shift()->_force_object;
	$self->or(
		FFR->file
		   ->name( '*.pl' ),
		FFR->file
		   ->name( qr/^[^.]+$/ )
		   ->exec( \&File::Find::Rule::Perl::_shebang ),
		);
}

sub File::Find::Rule::Perl::_shebang {
	local *SEARCHFILE;
	open SEARCHFILE, $_ or return !1;
	my $first_line = <SEARCHFILE>;
	close SEARCHFILE;
	return !1 unless defined $first_line;
	return $first_line =~ /^#!.*\bperl\b/;
}

=pod

=head2 perl_file

The C<perl_file> rule locates all files containing Perl code.

This includes all the files matching the above C<perl_module>,
C<perl_test>, C<perl_installer> and C<perl_script> rules.

=cut

sub File::Find::Rule::perl_file {
	my $self = shift()->_force_object;
	$self->file->or(
		FFR->name( '*.pm', '*.t', '*.pl', 'Makefile.PL', 'Build.PL' ),
		FFR->name( qr/^[^.]+$/ )
		   ->exec( \&File::Find::Rule::Perl::_shebang ),
		);
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Find-Rule-Perl>

For other issues, contact the maintainer

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<File::Find::Rule>, L<File::Find::Rule::PPI>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
