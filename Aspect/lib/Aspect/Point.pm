package Aspect::Point;

use strict;
use warnings;
use Carp                  ();
use Sub::Uplevel          ();
use Aspect::Point::Static ();

our $VERSION = '0.97_03';





######################################################################
# Constructor and Built-In Accessors

# sub new {
	# my $class = shift;
	# bless { @_ }, $class;
# }

sub pointcut {
	$_[0]->{pointcut};
}

sub sub_name {
	$_[0]->{sub_name};
}

sub wantarray {
	$_[0]->{wantarray};
}

sub params_ref {
	$_[0]->{params};
}

sub self {
	$_[0]->{params}->[0];
}

sub params {
	$_[0]->{params} = [ @_[1..$#_] ] if @_ > 1;
	return CORE::wantarray
		? @{$_[0]->{params}}
		: $_[0]->{params};
}





######################################################################
# Higher Level Methods

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
