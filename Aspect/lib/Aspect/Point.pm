package Aspect::Point;

=pod

=head1 NAME

Aspect::Point - Context information during advice code for a single join point

=head1 DESCRIPTION

The B<Aspect::Point> class family provides information and functionality about
the context of a single call of a single join point during the execution
of the advice code at that join point.

It is made available via the topic variable C<$_>.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp                  ();
use Sub::Uplevel          ();
use Aspect::Point::Static ();

our $VERSION = '0.97_04';





######################################################################
# Constructor and Built-In Accessors

# sub new {
	# my $class = shift;
	# bless { @_ }, $class;
# }

=pod

=head2 pointcut

  my $pointcut = $_->pointcut;

The C<pointcut> method provides access to the original join point specification
(as a tree of L<Aspect::Pointcut> objects) that the current join point matched
against.

Please note that the pointcut returned is the full and complete pointcut tree,
due to the heavy optimisation used on the actual pointcut code when it is run
there is no way at the time of advice execution to indicate which specific
conditions in the pointcut tree matched and which did not.

Returns an object which is a sub-class of L<Aspect::Pointcut>.

=cut

sub pointcut {
	$_[0]->{pointcut};
}

=pod

=head2 sub_name

  # Prints Full::Function::name
  before {
      print $_->sub_name . "\n";
  } call 'Full::Function::name';

The C<sub_name> method returns a string with the full resolved function name
at the join point the advice code is running at.

=cut

sub sub_name {
	$_[0]->{sub_name};
}

=pod

=head2 wantarray

  # Return differently depending on the calling context
  if ( $_->wantarray ) {
      $_->return_value(5);
  } else {
      $_->return_value(1, 2, 3, 4, 5);
  }

The C<wantarray> method returns the L<perlfunc/wantarray> context of the
call to the function for the current join point.

As with the core Perl C<wantarray> function, returns true if the function is
being called in list context, false if the function is being called in scalar
context, or C<undef> if the function is being called in void context.

=cut

sub wantarray {
	$_[0]->{wantarray};
}

=pod

=head2 params_ref

The C<params_ref> method returns a reference to an C<ARRAY> containing the list
of paramaters provided to the function. If the join point was a method call, the
array will contain the calling object or class as the first param, as per the
normal behaviour of object-oriented Perl code.

To enable more convenient and powerful uses of L<Aspect> in your code, the
C<ARRAY> reference returned is the actual live storage for the parameters that
L<Aspect> itself uses for the function params.

Thus, you can use the returned reference not just to access the parameters, but
to change them as well. For example, the following doubles the value of the
third parameter to the function C<Foo::bar>.

  before {
      $_->params_ref->[2] *= 2;
  } call 'Foo::bar';

=cut

sub params_ref {
	$_[0]->{params};
}

=pod

=head2 params

The C<params> method returns the list of parameters to the function as a list.
If the join point was a method call, the list will contain the calling object
or calss as the first element in the list, as per the normal behaviour of
object-oriented Perl code.

=cut

sub params {
	$_[0]->{params} = [ @_[1..$#_] ] if @_ > 1;
	return CORE::wantarray
		? @{$_[0]->{params}}
		: $_[0]->{params};
}

=pod

=head2 self

  after_returning {
      $_->self->save;
  } My::Foo::set;

The C<self> method is a convenience provided for when you are writing advice
that will be working with object-oriented Perl code. It returns the first the
first parameter to the method (which should be object), which you can then call
methods on.

The result is advice code that is much more natural to read, as you can see in
the above example where we implement an auto-save feature on the class
C<My::Foo>, writing the contents to disk every time a value is set without
error.

At present the C<self> method is implemented fairly naively, if used outside
of object-oriented code it will still return something (including C<undef> in
the case where there were no params to the join point function).

=cut

sub self {
	$_[0]->{params}->[0];
}





######################################################################
# Higher Level Methods

=pod

=head2 package_name

  # Prints Just::Package::name
  before {
      print $_->sub_name . "\n";
  } call 'Just::Package::name';

The C<package_name> parameter is a convenience wrapper around the C<sub_name>
method. Where C<sub_name> will return the fully resolved function name, the
C<package_name> method will return just the namespace of the package of the
join point.

=cut

sub package_name {
	my $name = $_[0]->{sub_name};
	return '' unless $name =~ /::/;
	$name =~ s/::[^:]+$//;
	return $name;
}

sub short_sub_name {
	my $name = $_[0]->{sub_name};
	return $name unless $name =~ /::/;
	$name =~ /::([^:]+)$/;
	return $1;
}

sub return_value {
	my $self = shift;

	if ( $self->{wantarray} ) {
		return @{$self->{return_value}} unless @_;

		# Normalise list-wise return behaviour
		# at mutation time, rather than everywhere else.
		# NOTE: Reuse the current array reference. This
		# causes the original return values to be cleaned
		# up immediately, and allows for a small
		# optimisation in the surrounding advice hook code.
		$self->{return_value} = \@_;
		$self->{exception}    = '';
		$self->{proceed}      = 0;
		return @_;
	}

	return $self->{return_value} unless @_;

	$self->{exception}    = '';
	$self->{proceed}      = 0;
	$self->{return_value} = shift;
}

# Accelerate the recommended cflow key
sub enclosing {
	$_[0]->{enclosing};
}

sub AUTOLOAD {
	my $self = shift;
	my $key  = our $AUTOLOAD;
	$key =~ s/^.*:://;
	Carp::croak "Key does not exist: [$key]" unless exists $self->{$key};
	return $self->{$key};
}

# Improves performance by not having to send DESTROY calls
# through AUTOLOAD, and not having to check for DESTROY in AUTOLOAD.
sub DESTROY () { }





######################################################################
# Optional XS Acceleration

BEGIN {
	local $@;
	eval <<'END_PERL';
use Class::XSAccessor 1.08 {
	replace => 1,
	getters => {
		'pointcut'   => 'pointcut',
		'sub_name'   => 'sub_name',
		'wantarray'  => 'wantarray',
		'params_ref' => 'params',
		'enclosing'  => 'enclosing',
	},
};
END_PERL
}

1;

__END__

=pod

=head1 NAME

Aspect::Point - The Join Point context

=head1 SYNOPSIS

  $pointcut = call qr/^Person::[gs]et_/
            & cflow qr/^Company::/;
  
  # using in 'before' advice code
  before {
     my $point = shift;             # Context is the only param to advice
     print $point->type;            # The advice type ('before')
     print $point->pointcut;        # The matching pointcut ($pointcut)
     print $point->sub_name;        # The full package_name::sub_name
     print $point->package_name;    # The package name ('Person')
     print $point->short_sub_name;  # The sub name (a get or set method)
     print $point->self;            # 1st parameter to the matching sub
     print $point->params->[1];     # 2nd parameter to the matching sub
     $point->return_value(4)        # Don't proceed and return immediately
     $point->original->(x => 3);    # Call matched sub independently
     $point->proceed(1);            # Continue to sub with context params
     print $point->enclosing->name; # Access cflow pointcut advice context
  } $pointcut;

=head1 DESCRIPTION

Advice code is called when the advice pointcut is matched. In this code,
there is often a need to access information about the join point context
of the advice. Information like:

What is the actual sub name matched?

What are the parameters in this call that we matched?

Sometimes you want to change the context for the matched sub, such as
appending a parameter or even stopping the matched sub from being called
at all.

You do all these things through the C<Join Point>, which is an object
that isa L<Aspect::Point>. It is the only parameter provided to the advice
code. It provides all the information required about the match context,
and allows you to change the behavior of the matched sub.

Note: Modifying parameters through the context in the code of an I<after>
advice, will have no effect, since the matched sub has already been called.

In a future release this will be fixed so that the context for each advice
type only responds to the methods relevant to that context, with the rest
throwing an exception.

=head2 Cflows

If the pointcut of an advice is composed of at least one C<cflow> the
advice code may require not only the context of the advice, but the join
point context of the cflows as well.

This is required if you want to find out, for example, what the name of the
sub that matched a cflow. In the synopsis example above, which method from
C<Company> started the chain of calls that eventually reached the get/set
on C<Person>?

You can access cflow context in the synopsis above, by calling:

  $point->enclosing;

You get it from the main advice join point by calling a method named after
the context key used in the cflow spec (which is "enclosing" if a custom name
was not provided, in line with AspectJ terminology). In the synopsis pointcut
definition, the cflow part was equivalent to:

  cflow enclosing => qr/^Company::/
        ^^^^^^^^^

An L<Aspect::Point::Static> will be created for the cflow, and you can access it
using the C<enclosing> method.

=head1 EXAMPLES

Print parameters to matched sub:

  before {
      print join ',', $_->params;
  } $pointcut;

Append a parameter:

  before {
      $_->params( $_params, 'extra-param' );
  } $pointcut;

Don't proceed to matched sub, return 4 instead:

  before {
      shift->return_value(4);
  } $pointcut;

Call matched sub again and again until it returns something defined:

  after {
      my $point  = shift;
      my $return = $point->return_value;
      while ( not defined $return ) {
          $return = $point->original($point->params);
      }
      $point->return_value($return);
  } $pointcut;

Print the name of the C<Company> object that started the chain of calls
that eventually reached the get/set on C<Person>:

  before {
      print shift->enclosing->self->name;
  } $pointcut;

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2011 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
