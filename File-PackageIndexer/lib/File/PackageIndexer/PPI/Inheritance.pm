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

sub handle_isa {
  my $indexer = shift;
  my $statement = shift;
  my $curpkg = shift;
  my $pkgs = shift;
  my $in_scheduled_block = shift;

  # skip if @ISA is modified in END block.
  return
    if defined $in_scheduled_block and $in_scheduled_block eq 'END';

  return
    unless $statement->isa("PPI::Statement");

  if (not defined $curpkg) {
    $curpkg = $indexer->lazy_create_pkg($indexer->default_package, $pkgs);
  }

  my $child = $statement->schild(0);
  return if not $child;

  if ($child->isa("PPI::Token::Word") and $child->content =~ /^(?:unshift|push)$/) {
    _handle_extend($indexer, $statement, $curpkg, $pkgs, $in_scheduled_block);
    return;    
  }
 
  # TODO, handle assignment 
}


sub _handle_extend {
  my $indexer = shift;
  my $statement = shift;
  my $curpkg = shift;
  my $pkgs = shift;
  my $in_scheduled_block = shift;

  my $child = $statement->schild(0);
  my $type = $child->content;

#  $child = $child->snext_sibling;
#  return unless defined $child;
  my $arguments = File::PackageIndexer::PPI::Util::list_structure_to_array($child);
  return
    unless defined $arguments
           and @$arguments
           and $arguments->[0] eq '@ISA';
  shift @$arguments;

  if ($type eq 'push')  {
    push @{ $in_scheduled_block eq 'BEGIN' ? $curpkg->{begin_isa} : $curpkg->{isa_push} }, @$arguments;
  }
  elsif ($type eq 'unshift') {
    unshift @{ $in_scheduled_block eq 'BEGIN' ? $curpkg->{begin_isa} : $curpkg->{isa_unshift} }, @$arguments;
  }
  else {
    die "Unknown operation on \@ISA: '$type'";
  }

  return();
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
