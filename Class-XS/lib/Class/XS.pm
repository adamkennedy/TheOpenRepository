package Class::XS;

use 5.006;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Class::XS', $VERSION);

Class::XS::_init();

sub CLASS_XS_DEBUG;
sub ATTR_PRIVATE;
sub ATTR_PROTECTED;
sub ATTR_PUBLIC;

sub AUTOLOAD {
  # This AUTOLOAD is used to 'autoload' constants from the constant()
  # XS function.
  my $constname;
  our $AUTOLOAD;
  ($constname = $AUTOLOAD) =~ s/.*:://;
  croak "&Class::XS::constant not defined" if $constname eq 'constant';
  my ($error, $val) = constant($constname);
  if ($error) { croak $error; }
  {
   no strict 'refs';
   *$AUTOLOAD = sub { $val };
  }
  goto &$AUTOLOAD;
}

sub import {
  my $own_class = shift;
  my ($caller_pkg) = caller();

  return if not @_;

  my %opts = @_;
  my $class = defined($opts{class}) ? $opts{class} : $caller_pkg;

  # todo: check attribute names for funny stuff!

  warn "\nCREATING CLASS $class\n" if CLASS_XS_DEBUG;
  # instantiates DESTROY, too.
  _registerClass($class);
  newxs_new($class . '::new');

  foreach my $baseClass (@{$opts{derive}||[]}) {
    warn "$class --> $baseClass" if CLASS_XS_DEBUG;

    my $file = $baseClass.".pm";
    $file =~ s/::/\//;
    if (not exists $INC{$file}) {
      eval "require $baseClass;";
      croak("Cannot load base class $baseClass of class $class.") if $@;
    }

    # set up inheritance for pure-Perl methods
    {
      no strict;
      push @{"${class}::ISA"}, $baseClass;
    }
    # set up attributes of base class
    my $attributeList = _getListOfAttributes($baseClass);
    eval 'use Data::Dumper; warn Dumper $attributeList' if CLASS_XS_DEBUG;
    _registerPublicAttributes(
      $class, [ keys %{$attributeList->[ATTR_PUBLIC]} ]
    );
  }

  my $public = $opts{public} || {};
  my $public_attrs = $public->{attributes} || [];
  _registerPublicAttributes($class, $public_attrs);
}

sub _registerPublicAttributes {
  my $class = shift;
  warn "CREATING ATTRIBUTES FOR CLASS $class\n" if CLASS_XS_DEBUG;
  my $attrs = shift;
  foreach my $attrName (@{$attrs||[]}) {
    my $attrIndex = _newAttribute($attrName, $class, ATTR_PUBLIC);
    warn "This is Class/XS.pm. Created attribute with name '$attrName' and global index '$attrIndex'\n" if CLASS_XS_DEBUG;
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
    public => {
      attributes => [qw(
        length mass name
      )],
    };
  
  package Dog;
  use Class::XS
    derive ['Animal'],
    public_attributes => [qw(
      leg_length
    )];
  
  # elsewhere
  package main;
  my $dog = Dog->new();
  $dog->set_length(80);
  $dog->set_mass(30);
  $dog->set_name("foo");
  $dog->set_leg_length(30);
  # ...
  my $length = $dog->get_length();
  my $mass   = $dog->get_mass();
  # ...

=head1 DESCRIPTION

Simple and fast creation of classes with guaranteed encapsulated storage
and fast accessors.

B<THIS IS AN EARLY RELEASE. LIKELY, THERE ARE SERIOUS BUGS!
USE AT YOUR OWN RISK!>

=head2 Usage

To construct a class with C<Class::XS>, you just put a
C<use Class::XS ...;> in your code and supply the specification of the class
as arguments to that call. Note that you cannot use C<Class::XS> to
generate B<the same class> twice. This is by design.

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

