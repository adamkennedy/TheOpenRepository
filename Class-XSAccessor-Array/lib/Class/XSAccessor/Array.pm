package Class::XSAccessor::Array;

use 5.006;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Class::XSAccessor::Array', $VERSION);

sub import {
  my $own_class = shift;
  my ($caller_pkg) = caller();

  my %opts = @_;

  my $replace = $opts{replace} || 0;

  my $read_subs = $opts{getters} || {};
  my $set_subs = $opts{setters} || {};

  foreach my $subname (keys %$read_subs) {
    my $hashkey = $read_subs->{$subname};
    _generate_accessor($caller_pkg, $subname, $hashkey, $replace, "getter");
  }

  foreach my $subname (keys %$set_subs) {
    my $hashkey = $set_subs->{$subname};
    _generate_accessor($caller_pkg, $subname, $hashkey, $replace, "setter");
  }
}

sub _generate_accessor {
  my ($caller_pkg, $subname, $hashkey, $replace, $type) = @_;

  if (not defined $hashkey) {
    croak("Cannot use undef as a hash key for generating an XS $type accessor. (Sub: $subname)");
  }

  if ($subname !~ /::/) {
    $subname = "${caller_pkg}::$subname";
  }

  if (not $replace) {
    my $sub_package = $subname;
    $sub_package =~ s/([^:]+)$// or die;
    my $bare_subname = $1;
    
    my $sym;
    {
      no strict 'refs';
      $sym = \%{"$sub_package"};
    }
    no warnings;
    local *s = $sym->{$bare_subname};
    my $coderef = *s{CODE};
    if ($coderef) {
      croak("Cannot replace existing subroutine '$bare_subname' in package '$sub_package' with XS $type accessor. If you wish to force a replacement, add the 'replace => 1' parameter to the arguments of 'use ".__PACKAGE__."'.");
    }
  }

  if ($type eq 'getter') {
    newxs_getter($subname, $hashkey);
  }
  else {
    newxs_setter($subname, $hashkey);
  }
}


1;
__END__

=head1 NAME

Class::XSAccessor::Array - Generate fast XS accessors without runtime compilation

=head1 SYNOPSIS
  
  package MyClassUsingArraysAsInternalStorage;
  use Class::XSAccessor::Array
    getters => {
      get_foo => 'foo', # 'foo' is the hash key to access
      get_bar => 'bar',
    },
    setters => {
      set_foo => 'foo',
      set_bar => 'bar',
    };
  # The imported methods are implemented in fast XS.
  
  # normal class code here.

=head1 DESCRIPTION

The module implements fast XS accessors both for getting at and
setting an object attribute. The module works only with objects
that are implement as B<arrays>. Refer to L<Class::XSAccessor> for
an implementation that works with hash-based objects.

A simple benchmark showed more than a factor of two performance
advantage over writing accessors in Perl.

While generally more obscure than hash-based objects,
objects using blessed arrays as internal representation
are a bit faster as its somewhat faster to access arrays than hashes.
Accordingly, this module is slightly faster (~10-15%) than
L<Class::XSAccessor>, which works on hash-based objects.

The method names may be fully qualified. In the example of the
synopsis, you could have written C<MyClass::get_foo> instead
of C<get_foo>.

=head1 CAVEATS

Probably wouldn't work if your objects are I<tied>. But that's a strange thing to do anyway.

Scary code exploiting strange XS features.

If you think writing an accessor in XS should be a laughably simple exercise, then
please contemplate how you could instantiate a new XS accessor for a new hash key
or array index that's only known at run-time. Note that compiling C code at run-time
a la Inline::C is a no go.

=head1 SEE ALSO

L<Class::XSAccessor>

L<AutoXS>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

