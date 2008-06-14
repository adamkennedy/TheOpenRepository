package Class::XS;

use 5.006;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '0.01_01';

require XSLoader;
XSLoader::load('Class::XS', $VERSION);

Class::XS::_init();

# "forward declarations" for the XS constants
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

# FIXME This whole thing is horrible spaghetti code...
sub import {
  my $own_class = shift;
  my ($caller_pkg) = caller();

  return if not @_;

  my %opts = @_;
  my $class = defined($opts{class}) ? $opts{class} : $caller_pkg;

  # todo: check attribute names for funny stuff!

  warn "\nCREATING CLASS $class\n" if CLASS_XS_DEBUG;

  _check_DESTROY_existance($class);

  # instantiates DESTROY, too.
  _registerClass($class);
  newxs_new($class . '::new');

  # for iteration over the scopes
  my %scopeMap = (
    public => ATTR_PUBLIC,
    protected => ATTR_PROTECTED,
    private => ATTR_PRIVATE,
  );
  # this will hold a hash of the following:
  # attrname => { get => GETSCOPE, set => SETSCOPE, originalClass => FROMWHICHCLASS }
  my $attrs = {};

  # import the attributes (etc) from potential base classes
  foreach my $baseClass (@{$opts{derive}||[]}) {
    warn "$class --> $baseClass" if CLASS_XS_DEBUG;

    my $file = $baseClass.".pm";
    $file =~ s/::/\//;
    if (not exists $INC{$file}) {
      eval "require $baseClass;";
      croak("Cannot load base class $baseClass of class $class. Reason: $@") if $@;
    }

    # set up inheritance for pure-Perl methods
    {
      no strict;
      push @{"${class}::ISA"}, $baseClass;
    }
    # set up attributes of base class
    my $attributeList = _getListOfAttributes($baseClass);
    eval 'use Data::Dumper; warn Dumper $attributeList' if CLASS_XS_DEBUG;

    my $originalClasses = $attributeList->{originalClass};
    foreach my $accessorType (qw(get set)) {
      foreach my $scope (keys %scopeMap) {
        my $scopeID = $scopeMap{$scope};

        foreach my $attrName (keys %{ $attributeList->{$accessorType}[$scopeID] }) {
          my $attr = ($attrs->{$attrName} ||= {});
          if (defined $attr->{$accessorType} and $attr->{$accessorType} != $scopeID) {
            croak("Multiple definition of ${accessorType}ter for attribute '$attrName' with conflicting scope");
          }
          $attr->{$accessorType} = $scopeID;
          $attr->{originalClass} = $originalClasses->{$attrName};
        }
      } # end foreach scope
    } # end foreach accessorType
  } # end foreach base class

  # process this class' object attributes
  foreach my $scope (keys %scopeMap) {
    my $scopeOpts = $opts{$scope} || {};
    # process "get" attributes
    foreach my $attrName (@{$scopeOpts->{get}||[]}) {
      my $attr = ($attrs->{$attrName} ||= {});
      if (defined $attr->{get}) {
        croak("Multiple definition of getter for attribute '$attrName' or redefinition in subclass");
      }
      $attr->{get} = $scopeMap{$scope};
      $attr->{originalClass} = $class;
    }
    # process "set" attributes
    foreach my $attrName (@{$scopeOpts->{set}||[]}) {
      my $attr = ($attrs->{$attrName} ||= {});
      if (defined $attr->{set}) {
        croak("Multiple definition of getter for attribute '$attrName' or redefinition in subclass");
      }
      $attr->{set} = $scopeMap{$scope};
      $attr->{originalClass} = $class;
    }
    # process "get_set" attributes
    foreach my $attrName (@{$scopeOpts->{get_set}||[]}) {
      my $attr = ($attrs->{$attrName} ||= {});
      if (defined $attr->{set}) {
        croak("Multiple definition of getter for attribute '$attrName' or redefinition in subclass");
      }
      if (defined $attr->{get}) {
        croak("Multiple definition of getter for attribute '$attrName' or redefinition in subclass");
      }
      $attr->{set} = $scopeMap{$scope};
      $attr->{get} = $scopeMap{$scope};
      $attr->{originalClass} = $class;
    }
  } # end foreach scope

  # check that scopes were defined for both setter and getter,
  # then install the new attribute
  foreach my $attrName (keys %$attrs) {
    my $scopeHash = $attrs->{$attrName};
    if (not exists $scopeHash->{set}) {
      croak("Missing getter declaration for attribute '$attrName'");
    }
    if (not exists $scopeHash->{set}) {
      croak("Missing setter definition for attribute '$attrName'");
    }
    _registerAttribute($class, $attrName, $scopeHash->{get}, $scopeHash->{set}, $scopeHash->{originalClass});
  }

  # install user defined destructors
  my $destructors = $opts{destructors} || [];
  push @$destructors, $opts{destructor} if ref($opts{destructor}) eq 'CODE';
  foreach my $sub (@$destructors) {
    if (not ref($sub) eq 'CODE') {
      croak("Destructors must be code references!");
    }
    _register_user_destructor($class, length($class), $sub);
  }
}

sub _registerAttribute {
  my $class = shift;
  my $attrName = shift;
  my $getScope = shift;
  my $setScope = shift;
  my $originalClass = shift;

  my $attrIndex = _newAttribute($attrName, $class, $getScope, $setScope, $originalClass);
  warn "This is Class/XS.pm. Created attribute with name '$attrName' and global index '$attrIndex'\n" if CLASS_XS_DEBUG;
  newxs_getter($class . '::get_' . $attrName, $attrIndex, $getScope);
  newxs_setter($class . '::set_' . $attrName, $attrIndex, $setScope);
}


# check whether a user class has a DESTROY sub already. For now,
# we'll just croak about it.
# TODO: Contemplate whether it makes sense to *include* that existing
# DESTROY in the list of user destructors. That might be DWIM but it
# also might be the opposite...
sub _check_DESTROY_existance {
  my $class = shift;
  no strict 'refs';
  my $table = \%{$class."::"};
  return if not exists $table->{"DESTROY"};
  local *symbol = $table->{"DESTROY"};
  my $destroy = *symbol{CODE};

  if (defined $destroy) {
    croak("Class '$class' has a DESTROY subroutine/destructor but uses Class::XS. This is a problem. Check the 'destructors' option to Class::XS.");
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
      get_set => [qw(
        length mass name
      )],
      get => [qw(
        length mass name
      )],
    };
  
  package Dog;
  use Class::XS
    derive ['Animal'],
    public => {
      attributes => [qw(
        leg_length
      )]
    };
  
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

=head1 CLASS SPECIFICATIONS

First, take a quick look at the C<SYNOPSIS> above. What you see there
should be reasonably self-explanatory. If not, write me an email.

Now, for the nitty gritty. The following are all the options that you can
pass to the C<use Class::XS> statement:

=head2 derive

You can specify other C<Class::XS> based classes as parent classes
with the C<derive> keyword. Multiple inheritance is supported.
If you want to inherit from normal Perl classes, the you'll have
to use the ordinary C<use base 'FooClass';> syntax for that.
The good news is: Mixing Perl and C<Class::XS> parent classes
is supported. (But see L<CAVEATS>.)

All attributes are inherited.

Syntax: C<derive =E<gt> ['parent1', 'parent2', ...]>.

=head2 public

This option is a container for attribute/method specifications.
By wrapping them in C<public =E<gt> { ... }>, they are 
marked as public attributes or methods. The corresponding
attribute getters and setters will be created as public
methods.
 
Currently, C<public> accepts only the C<attributes> option.

Syntax: C<public =E<gt> { attributes =E<gt> [...] }>

=head2 attributes

Only valid within a C<public =E<gt> { ... }> block!

Specifies the attributes of the class. Getter and
setter methods for each attribute will be generated
as C<get_attributename()> and C<set_attributename()>.

Syntax: C<public =E<gt> { attributes =E<gt> [ 'color', 'size' ] }>

=head2 destructors

With C<Class::XS> based classes, you cannot normally declare
destructors with C<sub DESTROY { ...}> because C<Class::XS>
uses a destructor of its own. So you can either do something
fragile and replace the DESTROY method which C<Class::XS>
placed in your class and call it from your own hook later,
or you just use the facilities of C<Class::XS>:

This option lets you define subroutines which will be run 
on object destruction just like a normal C<DESTROY> hook.

Syntax: C<destructors =E<gt> [ sub { my $self = shift; ... }, sub { ... } ]>

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

=over 2

=item

More documentation to come.

=item

Alpha code. Ugly code.

=item

Cannot inherit destructors!

=item

Cannot inherit attributes and/or accessors from non-Class::XS-based classes. This fails:

  package Foo;
  sub get_something { my $self = shift; return $self->{something}; }

  package Bar;
  use base 'Foo';
  use Class::XS
    public => {
      attributes => ['some_attribute']
    };

This will fail because a C<Class::XS> based class/object is not a hash. Therefore,
the superclass Foo's method C<get_something()> will trigger a C<"not a hashref"> warning.

=item

Do not call object methods as class methods. You won't like the results.

=item

Object destruction currently not so fast.

=back

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

