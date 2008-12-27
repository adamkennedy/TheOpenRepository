package File::PackageIndexer;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

use PPI;

use Class::XSAccessor
  constructor => 'new',
  accessors => {
    default_package => 'default_package',
  };


sub parse {
  my $self = shift;
  my $def_pkg = $self->default_package;
  $def_pkg = 'main' if not defined $def_pkg;

  my $doc = shift;
  if (not ref($doc) or not $doc->isa("PPI::Node")) {
    $doc = PPI::Document->new(\$doc);
  }
  
  my $curpkg;
  my $pkgs = {};

  # TODO: Accessor generators et al
  # TODO: Inheritance

  foreach my $token ( $doc->tokens ) {
    my $statement = $token->statement;
    next if not $statement;

    if ( $statement->class eq 'PPI::Statement::Sub' ) {
      my $subname = $statement->name;
      if (not defined $curpkg) {
        $curpkg = $self->_lazy_create_pkg($def_pkg, $pkgs);
      }
      $curpkg->{subs}->{$subname} = 1;
    }
    elsif ( $statement->class eq 'PPI::Statement::Package' ) {
      my $namespace = $statement->namespace;
      $curpkg = $self->_lazy_create_pkg($namespace, $pkgs);
    }
  }

  return $pkgs;
}

sub _lazy_create_pkg {
  my $self = shift;
  my $p_name = shift;
  my $pkgs = shift;
  return $pkgs->{$p_name} if exists $pkgs->{$p_name};
  $pkgs->{$p_name} = {
    subs => {},
    #isa  => [],
  };
  return $pkgs->{$p_name};
}


1;

__END__

=head1 NAME

File::PackageIndexer - Indexing of packages and subs

=head1 SYNOPSIS

  use File::PackageIndexer;
  my $indexer = File::PackageIndexer->new();
  my $pkgs = $indexer->parse( $ppi_document_or_code_string );
  
  use Data::Dumper;
  print Dumper $pkgs;
  # prints something like:
  # {
  #   Some::Package => {
  #     subs => {
  #       new => 1,
  #       foo => 1,
  #     },
  #   },
  #   ... other pkgs ...
  # }

=head1 DESCRIPTION

Parses a piece of Perl code using PPI and tries to find all subs
and their packages.

Currently, this simply finds package statements and plain subroutine
declarations. In the future, it should hopefully support various
accessor generators and similar tools.

=head1 METHODS

=head2 new

Creates a new indexer object. Optional parameters:

=over 2

=item default_package

The default package to assume a subroutine is in if no
package statement was found beforehand. Defaults to C<main>.

=back

=head2 default_package

Get/set default package.

=head2 parse

Parses a piece of code. Alternatively, you may pass in a C<PPI::Node>
or C<PPI::Document> object.

Returns a simple hash-ref based structure containing the
packages and subs found in the code. General structure:

  {
    'Package::Name' => {
      subs => {
        subname1 => 1,
        subname2 => 1,
        ... more subs ...
      },
    },
    ... more packages ...
  }

=head1 SEE ALSO

Implemented using L<PPI>.

=head1 TODO

Dependencies.

Accessor generators.

Moose.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
