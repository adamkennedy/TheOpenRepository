package Class::XS;

use 5.006;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Class::XS', $VERSION);

Class::XS::_init();

sub import {
  my $own_class = shift;
  my ($caller_pkg) = caller();

  my %opts = @_;
  my $class = defined($opts{class}) ? $opts{class} : $caller_pkg;

  # todo: check attribute names for funny stuff!

  # instantiates DESTROY, too.
  _registerClass($class);

  newxs_new($class . '::new');

  foreach my $attrName (@{$opts{public_attributes}||[]}) {
    my $attrIndex = _newAttribute($class);
    newxs_getter($class . '::get_' . $attrName, $attrIndex);
    newxs_setter($class . '::set_' . $attrName, $attrIndex);
  }
}

1;
__END__

=head1 NAME

Class::XS - Simple and fast classes

=head1 SYNOPSIS
  
  package Animal;
  use Class::XS
    public_attributes => [qw(
      length mass name
    )];
  
  # elsewhere
  package main;
  my $animal = Animal->new();
  $animal->set_length(150);
  $animal->set_mass(60);
  $animal->set_name("foo");
  # ...
  my $length = $animal->get_length();
  my $mass   = $animal->get_mass();
  # ...

=head1 DESCRIPTION

Simple and fast creation of classes with guaranteed encapsulated storage
and fast accessors.

B<THIS IS AN EARLY RELEASE. LIKELY, THERE ARE SERIOUS BUGS!
USE AT YOUR OWN RISK!>

=head1 PERFORMANCE

Take the values with a grain of salt. Simple benchmarks.
See F<benchmark/performance.pl> in the distribution tarball.

Accessors are much faster than ordinary Perl accessors
(~2-3 times as fast as normal Perl accessors).

Object creation is about 20% faster than the equivalent Perl code.
Note that the C<new()> method currently does not allow any parameters.
This may become an option in a future release.

Object destruction is about 20% slower than normal object destruction
if there is an empty DESTROY method. It is significanty slower than
normal object destruction. If the time taken for object creation and
destruction are taken together, objects created from C<Class::XS>
based classes are approximately 10% faster than normal classes with
an empty DESTROY method and 35-40% slower than normal classes without
any DESTROY method at all. This is because the object creation is
in all cases slower than the object destruction.

=head1 CAVEATS

More documentation to come.

Do not call object methods as class methods. You won't like the results.

Alpha code. Ugly code.

Object destruction currently not so fast.

=head1 SEE ALSO

L<Class::XSAccessor>
L<Class::XSAccessor::Array>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

