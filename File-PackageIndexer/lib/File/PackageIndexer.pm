package File::PackageIndexer;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

use PPI;
require File::PackageIndexer::PPI::Util;
require File::PackageIndexer::PPI::ClassXSAccessor;

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
  if (not ref($doc)) {
    return();
  }
  
  my $curpkg;
  my $pkgs = {};

  # TODO: More accessor generators et al
  # TODO: Inheritance
  # TODO: package statement scopes

  foreach my $token ( $doc->tokens ) {
    # find Class->method and __PACKAGE__->method
    my ($callee, $methodname) = File::PackageIndexer::PPI::Util::is_class_method_call($token);

    if ($callee and $methodname =~ /^(?:mk_(?:[rw]o_)?accessors)$/) {
      # resolve __PACKAGE__ to current package
      if ($callee eq '__PACKAGE__') {
        $callee = defined($curpkg) ? $curpkg->{name} : $def_pkg;
      }

      my $args = $token->snext_sibling->snext_sibling->snext_sibling; # class->op->method->structure
      if (defined $args and $args->isa("PPI::Structure::List")) {
        my $list = File::PackageIndexer::PPI::Util::list_structure_to_array($args);
        if (@$list) {
          my $pkg = lazy_create_pkg($callee, $pkgs);
          $pkg->{subs}{$_} = 1 for @$list;
        }
      }

    }


    my $statement = $token->statement;
    next if not $statement;

    # new sub declaration
    if ( $statement->class eq 'PPI::Statement::Sub' ) {
      my $subname = $statement->name;
      if (not defined $curpkg) {
        $curpkg = lazy_create_pkg($def_pkg, $pkgs);
      }
      $curpkg->{subs}->{$subname} = 1;
    }
    # new package statement
    elsif ( $statement->class eq 'PPI::Statement::Package' ) {
      my $namespace = $statement->namespace;
      $curpkg = lazy_create_pkg($namespace, $pkgs);
    }
    # use()
    elsif ( $statement->class eq 'PPI::Statement::Include' ) {
      $self->_handle_includes($statement, $curpkg, $pkgs);
    }
  }

  # prepend compile-time declared inheritance to the
  # run-time ISA.
  foreach my $pkgname (keys %$pkgs) {
    my $pkg = $pkgs->{$pkgname};
    unshift @{$pkg->{isa}}, @{$pkg->{begin_isa}};
    delete $pkg->{begin_isa};
  }

  return $pkgs;
}

# generate empty, new package struct
sub lazy_create_pkg {
  my $p_name = shift;
  my $pkgs = shift;
  return $pkgs->{$p_name} if exists $pkgs->{$p_name};
  $pkgs->{$p_name} = {
    name => $p_name,
    subs => {},
    isa  => [],
    begin_isa  => [], # temporary storage for compile-time inheritance, will be deleted before returning from parse()
  };
  return $pkgs->{$p_name};
}


# try to deduce info from module loads
sub _handle_includes {
  my $self = shift;
  my $statement = shift;
  my $curpkg = shift;
  my $pkgs = shift;

  return
    if $statement->type ne 'use'
    or not defined $statement->module;

  my $module = $statement->module;

  if ($module =~ /^Class::XSAccessor(?:::Array)?$/) {
    File::PackageIndexer::PPI::ClassXSAccessor::handle_class_xsaccessor($statement, $curpkg, $pkgs);
  }

  # TODO: handle other generating modules loaded via use
  
  # TODO: Elsewhere, we need to handle Class->import()!
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
declarations and supports some accessor generators (C<Class::Accessor>
and C<Class::XSAccessor(::Array)>).

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

Parses a given  piece of code. Alternatively, you may
pass in a C<PPI::Node> or C<PPI::Document> object.

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

Inheritance.

Exporting.

Other accessor generators. Currently supporting
C<Class::XSAccessor>, C<Class::XSAccessor::Array>, and modules that use the C<Class::Accessor>
style interface a la C<Class->mk_accessors(qw(foo bar))>.

Moose. This is going to be tough, but mandatory.

C<Class->import(...)> is currently not handled akin to C<use Class ...>.

General dependency resolution.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
