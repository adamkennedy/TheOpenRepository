package File::PackageIndexer::PPI::Inheritance;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';


# The base case
sub handle_base {
  my $indexer = shift;
  my $statement = shift;
  my $curpkg = shift;
  my $pkgs = shift;
  if (not defined $curpkg) {
    $curpkg = $indexer->lazy_create_pkg($indexer->default_package, $pkgs);
  }

  my $list_start = $statement->schild(0)->snext_sibling;
  my $classes = File::PackageIndexer::PPI::Util::list_structure_to_array($list_start);

  return
    if not defined $classes or ref($classes) ne 'ARRAY';

  # remove options if 'parent'
  if ($list_start->content() eq 'parent') {
    @$classes = grep $_ !~ /^-/, @$classes;
  }

  push @{$curpkg->{begin_isa}}, @$classes
    if defined $classes and ref($classes) eq 'ARRAY';

  return 1;
}



1;

__END__

=head1 NAME

File::PackageIndexer::PPI::Inheritance - Misc. functions for determining inheritance

=head1 DESCRIPTION

No user-serviceable parts inside.

=head1 SEE ALSO

L<File::PackageIndexer>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
