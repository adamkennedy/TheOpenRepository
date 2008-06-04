package Tie::Scalar::File;

=pod

=head1 NAME

Tie::Scalar::File - Tie a scalar to a file on disk

=head1 SYNOPSIS

  # Object usage
  my $file1 = Tie::Scalar::File->new( 'file.txt' );
  
  # Traditional usage
  my $file2;
  tie $file2, 'Tie::Scalar::File';

=head1 DESCRIPTION

B<Tie::Scalar::File> is a simple convenience class intended for use in
code that needs to quickly examine, append to or (in particular) apply
a search/replace regular expression to a file.

The tied scalar does not maintain a copy of the file in memory, nor
does it maintain a connection to, or lock on, the file.

It simply reads from the file when you do an operation that needs to 
examine the file, or clobbers the file when you need to do an operation
that modifies the file (or both if needed).

As a simple module meant for simple tasks (for now at least) very little
sophistication is provided. Files are read using default three-argument
open calls (so for portability should only be used on ASCII mode on Win32)
and assume the file has local newlines.

Tieing to binary files or unicode files is currently not supported at
this time.

=head1 METHODS

See L<Tie::Scalar> for details.

=cut

use 5.005;
use strict;
use Tie::Scalar ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.01';
	@ISA     = 'Tie::Scalar';
}

sub TIEHASH {
	my $class = shift;
	my $file  = shift;

}

1;

=pod

=head1 TO DO

- Additional features will be added on demand, based on RT tickets.

=head1 SUPPORT

Bugs and featur requests should be submitted via the CPAN bug tracker,
located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Scalar-File>

For general comments or other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Tie::Scalar>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
