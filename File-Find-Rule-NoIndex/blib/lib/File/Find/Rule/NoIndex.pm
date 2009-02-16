package File::Find::Rule::NoIndex;

=pod

=head1 NAME

File::Find::Rule::NoIndex - Follow the rules in META.yml no_index keys

=head1 SYNOPSIS

  use File::Find::Rule          ();
  use File::Find::Rule::NoIndex ();
  
  # Find all Perl files smaller than 10k
  my @files = File::Find::Rule->no_index(
      directory
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

use 5.006;
use strict;
use File::Find::Rule ();

use vars qw{$VERSION @ISA @EXPORT};
BEGIN {
	$VERSION = '0.01';
	@ISA     = 'File::Find::Rule';
	@EXPORT  = @File::Find::Rule::EXPORT;
}

use constant FFR => 'File::Find::Rule';





#####################################################################
# File::Find::Rule Method Addition

=pod

=head2 no_index

The C<no_index> method applies a set of rules as per the no_index section
in a C<META.yml> file.

=cut

sub File::Find::Rule::no_index {
	my $find = $_[0]->_force_object;
	return $find->or(
		FFR->exec( sub {
			my $shortname = shift;
			my $path      = shift;
			my $fullname  = shift;

			1;

		} ),
		FFR->new,
		);
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Find-Rule-NoIndex>

For other issues, contact the maintainer

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<File::Find::Rule>, L<File::Find::Rule::Perl>

=head1 COPYRIGHT

Copyright 2006 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
