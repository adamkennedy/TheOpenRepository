package Aspect;

=pod

=head1 NAME

Aspect - Aspect-Oriented Programming (AOP) for Perl

=head1 SYNOPSIS

  use Aspect;
  
  
  
  # Run some code "Advice" before a particular function
  before {
      print "About to call create\n";
  } call 'Person::create';
  
  
  
  # Run Advice after several methods and hijack their return values
  after {
      print "Called getter/setter " . $_->sub_name . "\n";
      $_->return_value(undef);
  } call qr/^Person::[gs]et_/;
  
  
  
  # Run Advice conditionally based on multiple factors
  before {
      print "Calling a get method in void context within Tester::run_tests";
  } wantvoid
  & ( call qr/^Person::get_/ & ! call 'Person::get_not_trapped' )
  & cflow 'Tester::run_tests';
  
  
  
  # Context-aware runtime hijacking of a method if certain condition is true
  around {
      if ( $_->self->customer_name eq 'Adam Kennedy' ) {
          # Ensure I always have cash
          $_->return_value('One meeeelion dollars');
      } else {
          # Take a dollar off everyone else
          $_->proceed;
          $_->return_value( $_->return_value - 1 );
      }
  } call 'Bank::Account::balance';
  
  
  
  # Catch and handle unexpected exceptions in a function into a formal object
  after_throwing {
      $_->exception(
          Exception::Unexpected->new($_->exception)
      );
  } ! throwing qr/^Exception::(?:Expected|Unexpected)$/;
  
  
  
  # Run Advice only on the outmost of a recursive series of calls
  around {
    print "Starting recursive child search\n";
    $_->proceed;
    print "Finished recursive child search\n";
  } call 'Person::find_child' & highest;
  
  
  
  # Run Advice only during the current lexical scope
  SCOPE: {
      my $hook = before {
          print "About to call create\n";
      } call 'Person::create';
  
      # Advice will run for this call
      Person->create('Bob');
  }
  
  # Advice won't run for this call
  Person->create('Tom');
  
  
  
  # Use a pre-packaged collection "Aspect" of Advice rules to change a class
  aspect Singleton => 'Foo::new';
  
  
  
  # Define debugger breakpoints with high precision and conditionality
  aspect Breakpoint => call qr/^Foo::.+::Bar::when_/ & wantscalar & highest;
  
  
  
=head1 DESCRIPTION

=head2 What is Aspect-Oriented Programming?

Aspect-Oriented Programming (AOP) allows you to modularise concerns that
would otherwise cut across many parts of a program and be problematic to
implement and maintain.

One common example is logging, where many small fragments code are typically
spread throughout your entire codebase.

Another example is the implementation of design patterns, which combine or
manipulate various kinds of classes in particular ways produce a known type of
higher order behavior.

Because Aspect-Oritented Programming moves this scattered code into a single
place, another major benefit is conditional compilation.

Features implemented via Aspects can be compiled in only in certain situations,
and because of this Aspects are useful when debugging or testing large complex
programs.

Aspects can implement features necesary for correctness of programs such as
reactivity or synchronisation, and it can be used to add checking assertions
to your or other people's modules.

If necesary (although not recommended) you can also do "Monkey Patching",
hijacking the functionality of some other module to act different when used in
your program than when other everywhere else.

Aspects can be used to implement space or time optimisations. One popular use
case is to add caching to a module or function that does not natively implement
caching.

See L<http://www.aosd.net> for more info.

=head2 About This Implementation

The Perl B<Aspect> module tries to closely follow the terminology of the
Java AspectJ project wherever possible (L<http://eclipse.org/aspectj>).

However due to the dynamic nature of the Perl language, several C<AspectJ>
features are useless for us: exception softening, mixin support, out-of-class
method declarations, annotations, and others.

The Perl B<Aspect> module is focused on subroutine matching and wrapping.

It allows you to select collections of subroutines and conditions using a
flexible pointcut language, and modify their behavior in any way you want.

In this regard it provides a similar set of functionality to L<Hook::LexWrap>,
but with much more precision and with much more control and maintainability
as the complexity of what you are doing increases.

In addition, where the Java implementation of Aspect-Oriented Programming is
only able to integrate at compile time, the nature of Perl means that the
B<Aspect> module can weave in aspect code at run-time, and pointcuts can take
advantage of run-time information and Perl-specific features like closures.

This allows the Perl implementation of Aspect-Oriented Programming to be
stateful and adaptive in a way that Java nroamlly cannot be.

=head2 Terminology

One of the more opaque aspects (no pun intended) of Aspect-Oriented programming
is that it has an entire unique set of terms that can be confusing for people
learning to use the B<Aspect> module.

In this section, we will attempt to define all the major terms in a way that
will hopefully make sense to Perl programmers.

=head3 What is an Aspect?

An I<Aspect> is a modular unit of cross-cutting implementation, consisting of
"Advice" on "Pointcuts" (we'll define those two shortly, don't worry if they
don't make sense for now).

In Perl, this would typically mean a package or module containing declarations
of where to inject code, the code to run at these points, and any variables or
support functions needed by the injected functionality.

The most critical point here is that the Aspect represents a collection of
many different injection points which collectively implement a single function
or feature and which should be enabled on an all or nothing basis.

For example, you might implement the Aspect B<My::SecurityMonitor> as a module
which will inject hooks into a dozen different strategic places in your
program to watch for valid-but-suspicious values and report these values to
an external network server.

Aspects can often written to be highly reusable, and be released via the CPAN.
When these generic aspects are written in the special namespace
L<Aspect::Library> they can be called using the following special shorthand.

  use Aspect;
  
  # Load and enable the Aspect::Library::NYTProf aspect to constrain profiling
  # to only the object constructors for each class in your program.
  aspect NYTProf => call qr/^MyProgram\b.*::new$/;

=head3 What is a Pointcut?

A I<Join Point> is a well-defined location at a point in the execution of a
program at which Perl can inject functionality, in effect joining two different
bits of code together.

In the Perl B<Aspect> implementation, this consists only of the execution of
named subroutines on the symbol table such as C<Foo::Bar::function_name>.

In other languages, additional join points can exist such as the instantiation
or destruction of an object or the static initialisation of a class.

A I<Pointcut> is a well-defined set of join points, and any conditions that
must be true when at these join points.

Example include "All public methods in class C<Foo::Bar>" or "Any non-recursive
call to the function C<Some::recursive_search>".

We will discuss each of the available pointcut types later in this document.

In addition to the default pointcut types it is possible to write your own
specialised pointcut types, although this is challenging due to the complex
API they follow to allow aggressive multi-pass optimisation.

See L<Aspect::Pointcut> for more information.

=head3 What is Advice?

I<Advice> is code designed to run automatically at all of the join points in
a particular pointcut. Advice comes in several types, instructing that the
code be run C<before>, C<after> or C<around> (in place of) the different join
points in the pointcut.

Advice code is introduced lexically to the target join points. That is, the
new functionality is injected in place to the existing program rather the
class being extended into some new version.

For example, function C<Foo::expensive_calculation> may not support caching
because it is unsafe to do so in the general case. But you know that in the
case of your program, the reasons it is unsafe in the general case don't apply.

So for your program you might use the L<Aspect::Library::Memoise> aspect to
"Weave" Advice code into the C<Foo> class which adds caching to the function
by integrating it with L<Memoise>.

Each of the different advice types needs to be used slightly differently, and
are best employed for different types of jobs. We will discuss the use of each
of the different advice types later in this document.

In addition to the default pointcut types, it is (theoretically) possible to
write your own specialised Advice types, although this would be extremely
difficult and probably involve some form of XS programming.

For the brave, see L<Aspect::Advice> and the source for the different advice
classes for more information.

=head3 What is Weaving?

I<Weaving> is the installation of advice code to the subs that match a pointcut,
or might potentially match depending on certain run-time conditions.

In the Perl B<Aspect> module, weaving happens on the declaration of each
advice block. Unweaving happens when a lexically-created advice variable goes
out of scope.

Unfortunately, due to the nature of the mechanism B<Aspect> uses to hook into
function calls, unweaving can never be guarenteed to be round-trip clean.

While the pointcut matching logic and advice code will never be run for unwoven
advice, it may be necesary to leave the underlying hooking artifact in place on
the join point indefinitely (imposing a small performance penalty and preventing
clean up of the relevant advice closure from memory).

Programs that repeatedly weave and unweave during execution will thus gradually
slow down and leak memory, and so is discouraged despite being permitted.

If advice needs to be repeatedly enabled and disabled you should instead
consider using the C<if_true> pointcut and a variable in the aspect package or
a closure to introduce a remote "on/off" switch for the aspect.

into the advice code.

  package My::Aspect;
  
  my $switch = 1;
  
  before {
      print "Calling Foo::bar\n";
  } call 'Foo::bar' & if_true { $switch };
  
  sub enable {
      $switch = 1;
  }
  
  sub disable {
      $switch = 0;
  }
  
  1;

Under the covers weaving is done using a mechanism that is very similar to
the venerable L<Hook::LexWrap>, although in some areas B<Aspect> will try to
make use of faster mechanisms if it knows these are safe.

=head2 Feature Summary

=over

=item *

Create permanent pointcuts, advice, and aspects at compile time or run-time.

=item *

Flexible pointcut language: select subs to match using string equality,
regexp, or C<CODE> ref. Match currently running sub, a sub in the call
flow, calls in particular void, scalar, or array contexts, or only the highest
call in a set of recursive calls.

=item *

Build pointcuts composed of a logical expression of other pointcuts,
using conjunction, disjunction, and negation.

=item *

In advice code, you can modify parameter list for matched sub, modify return
value, throw or supress exceptions, decide whether or not to proceed to matched
sub, access a C<CODE> ref for matched sub, and access the context of any call
flow pointcuts that were matched, if they exist.

=item *

Add/remove advice and entire aspects lexically during run-time. The scope of
advice and aspect objects, is the scope of their effect (This does, however,
come with some caveats).

=item *

A basic library of reusable aspects. A base class makes it easy to create your
own reusable aspects. The L<Aspect::Library::Memoize> aspect is an
example of how to interface with AOP-like modules from CPAN.

=back

=head2 Using Aspect.pm

The B<Aspect> package allows you to create pointcuts, advice, and aspects in a
simple declarative fashion. This declarative form is a simple facade on top of
the Perl AOP framework, which you can also use directly if you need the
increased level of control or you feel the declarative form is not clear enough.

For example, the following two examples are equivalent.

  use Aspect;
  
  # Declarative advice creation
  before {
      print "Calling " . $_->sub_name . "\n";
  } call 'Function::one'
  | call 'Function::two';
  
  # Longhand advice creation
  Aspect::Advice::Before->new(
      Aspect::Pointcut::Or->new(
          Aspect::Pointcut::Call->new('Function::one'),
          Aspect::Pointcut::Call->new('Function::two'),
      ),
      sub {
          print "Calling " . $_->sub_name . "\n";
      },
  );

You will be mostly working with this package (B<Aspect>) and the
L<Aspect::Point> package, which provides the methods for getting information
about the call to the join point within advice code.

When you C<use Aspect;> you will import a family of around fifteen
functions. These are all factories that allow you to create pointcuts,
advice, and aspects.

=head1 FUNCTIONS

The following functions are exported by default (and are documented as such)
but are also available directly in Aspect:: namespace as well if needed.

They are documented in order from the simplest and and most common pointcut
declarator to the highest level declarator for enabling complete aspect classes.

=cut

use 5.008002;
use strict;
use warnings;

# Added by eilara as hack around caller() core dump
# NOTE: Now we've switched to Sub::Uplevel can this be removed?
# -- ADAMK
use Carp::Heavy                    ();
use Carp                           ();
use Params::Util              1.00 ();
use Sub::Install              0.92 ();
use Sub::Uplevel            0.2002 ();
use Aspect::Pointcut               ();
use Aspect::Pointcut::If           ();
use Aspect::Pointcut::Or           ();
use Aspect::Pointcut::And          ();
use Aspect::Pointcut::Not          ();
use Aspect::Pointcut::Call         ();
use Aspect::Pointcut::Cflow        ();
use Aspect::Pointcut::Highest      ();
use Aspect::Pointcut::Throwing     ();
use Aspect::Pointcut::Wantarray    ();
use Aspect::Advice                 ();
use Aspect::Advice::After          ();
use Aspect::Advice::AfterReturning ();
use Aspect::Advice::AfterThrowing  ();
use Aspect::Advice::Around         ();
use Aspect::Advice::Before         ();
use Aspect::AdviceContext          ();

our $VERSION = '0.97_03';

# Track the location of exported functions so that pointcuts
# can avoid accidentally binding them.
our %EXPORTED = ();





######################################################################
# Public (Exported) Functions

=pod

=head2 call

  my $single   = call 'Person::get_address';
  my $multiple = call qr/^Person::get_/;
  my $complex  = call sub { lc($_[0]) eq 'person::get_address' };
  my $object   = Aspect::Pointcut::Call->new('Person::get_address');

The most common pointcut is C<call>. All three of the examples will match the
calling of C<Person::get_address()> as defined in the symbol table at the
time an advice is declared.

The C<call> declarator takes a single parameter which is the pointcut spec,
and can be provided in three different forms.

B<string>

Select only the specific full resolved subroutine whose name is equal to the
specification string. 

For example C<call 'Person::get'> will only match the plain C<get> method
and will not match the longer C<get_address> method.

B<regexp>

Select all subroutines whose name matches the regular expression.

The following will match all the subs defined on the C<Person> class, but not
on the C<Person::Address> or any other child classes.

  $p = call qr/^Person::\w+$/;

B<CODE>

Select all subroutines where the supplied code returns true when passed a
full resolved subroutine name as the only parameter.

The following will match all calls to subroutines whose names are a key in the
hash C<%subs_to_match>:

  $p = call sub {
      exists $subs_to_match{$_[0]};
  }

=back

For more information on the C<call> pointcut see L<Aspect::Pointcut::Call>.

=cut

sub call ($) {
	Aspect::Pointcut::Call->new(@_);
}

=pod

=head2 cflow

  before {
     print "Called My::foo somewhere within My::bar\n";
  } call 'My::foo'
  & cflow 'My::bar';

The C<cflow> declarator is used to specify that the join point must be somewhere
within the control flow of the C<My::bar> function. That is, at the time
C<My::foo> is being called somewhere up the call stack is C<My::bar>.

The parameters to C<cflow> are identical to the parameters to C<call>.

Due to an idiosyncracy in the way C<cflow> is implemented, they do not always
parse properly well when joined with an operator. In general, you should use
any C<cflow> operator last in your pointcut specification, or use explicit
braces for it.

  # This works fine
  my $x = call 'My::foo' & cflow 'My::bar';
  
  # This will error
  my $y = cflow 'My::bar' & call 'My::foo';
  
  # Use explicit braces if you can't have the flow last
  my $z = cflow('My::bar') & call 'My::foo';

For more information on the C<cflow> pointcut, see L<Aspect::Pointcut::Cflow>.

=cut

sub cflow ($;$) {
	Aspect::Pointcut::Cflow->new(@_);
}

=pod

=head2 wantlist

  my $pointcut = call 'Foo::bar' & wantlist;

The C<wantlist> pointcut traps a condition based on Perl C<wantarray> context,
when a function is called in list context. When used with C<call>, this
pointcut can be used to trap list-context calls to one or more functions, while
letting void or scalar context calls continue as normal.

For more information on the C<wantlist> pointcut see
L<Aspect::Pointcut::Wantarray>.

=cut

sub wantlist () {
	Aspect::Pointcut::Wantarray->new(1);
}

=pod

=head2 wantscalar

  my $pointcut = call 'Foo::bar' & wantscalar;

The C<wantscalar> pointcut traps a condition based on Perl C<wantarray> context,
when a function is called in scalar context. When used with C<call>, this
pointcut can be used to trap scalar-context calls to one or more functions,
while letting void or list context calls continue as normal.

For more information on the C<wantscalar> pointcut see
L<Aspect::Pointcut::Wantarray>.

=cut

sub wantscalar () {
	Aspect::Pointcut::Wantarray->new('');
}

=pod

=head2 wantvoid

  my $bug = call 'Foo::get_value' & wantvoid;

The C<wantvoid> pointcut traps a condition based on Perl C<wantarray> context,
when a function is called in void context. When used with C<call>, this pointcut
can be used to trap void-context calls to one or more functions, while letting
scalar or list context calls continue as normal.

This is particularly useful for methods which make no sense to call in void
context, such as getters or other methods calculating and returning a useful
result.

For more information on the C<wantvoid> pointcut see
L<Aspect::Pointcut::Wantarray>.

=cut

sub wantvoid () {
	Aspect::Pointcut::Wantarray->new(undef);
}

=pod

=head2 highest

  my $entry = call 'Foo::recurse' & highest;

The C<highest> pointcut is used to trap the first time a particular function
is encountered, while ignoring any subsequent recursive calls into the same
pointcut.

It is unusual in that unlike all other types of pointcuts it is stateful, and
so some detailed explaination is needed to understand how it will behave.

Pointcut declarators follow normal Perl precedence and shortcutting in the same
way that a typical set of C<foo() and bar()> might do for regular code.

When the C<highest> is evaluated for the first time it returns true and a
counter is to track the depth of the call stack. This counter is bound to the
join point itself, and will decrement back again once we exit the advice code.

If we encounter another function that is potentially contained in the same
pointcut, then C<highest> will always return false.

In this manner, you can trigger functionality to run only at the outermost
call into a recursive series of functions, or you can negate the pointcut 
with C<! highest> and look for recursive calls into a function when there
shouldn't be any recursion.

In the current implementation, the semantics and behaviour of pointcuts
containing multiple highest declarators is not defined (and the current
implementation is also not amenable to supporting it).

For these reasons, the usage of multiple highest declarators such as in the
following example is not support, and so the following will throw an exception.

  before {
      print "This advice will not compile\n";
  } wantscalar & (
      (call 'My::foo' & highest)
      |
      (call 'My::bar' & highest)
  );

This limitation may change in future releases. Feedback welcome.

For more information on the C<highest> pointcut see
L<Aspect::Pointcut::Highest>.

=cut

sub highest () {
	Aspect::Pointcut::Highest->new;
}

=pod

=head2 throwing

  my $string = throwing qr/does not exist/;
  my $object = throwing 'Exception::Class';

The C<throwing> pointcut is used with the C<after> (and C<after_throwing>) to
restrict the pointcut so advice code is only fired for a specific die message
or a particular exception class (or subclass).

The C<throwing> declarator takes a single parameter which is the pointcut spec,
and can be provided in two different forms.

B<regexp>

If a regular expression is passed to C<throwing> it will be matched against
the exception if and only if the exception is a plain string.

Thus, the regexp form can be used to trap unstructured errors emitted by C<die>
or C<croak> while B<NOT> trapping any formal exception objects of any kind.

B<string>

If a string is passed to C<throwing> it will be treated as a class name and
will be matched against the exception via an C<isa> method call if and only
if the exception is an object.

Thus, the string form can be used to trap and handle specific types of
exceptions while allowing other types of exceptions or raw string errors to
pass through.

For more information on the C<throwing> pointcut see
L<Aspect::Pointcut::Throwing>.

=cut

sub throwing ($) {
	Aspect::Pointcut::Throwing->new(@_);
}

=pod

=head2 if_true

  # Intercept an adjustable random percentage of calls to a function
  our $RATE = 0.01;
  
  before {
      print "The few, the brave, the 1%\n";
  } call 'My::foo'
  & if_true {
      rand() < $RATE
  };

Because of the lengths that B<Aspect> goes to internally to optimise the
selection and interception of calls, writing your own custom pointcuts can
be very difficult.

When a custom or unusual pattern of interception is needed, often all that is
desired is to extend a relatively normal pointcut with an extra caveat.

To allow for this scenario, B<Aspect> provides the C<is_true> pointcut.

This pointcut allows you to specify any arbitrary code to match on. This code
will be executed at run-time if the join point matches all previous conditions.

The join point matches if the function or closure returns true, and does not
match if the code returns false or nothing at all.

=cut

sub if_true (&) {
	Aspect::Pointcut::If->new(@_);
}

=pod

=head2 before

  before {
      # Don't call the function, return instead
      $_->return_value(1);
  } call 'My::foo';

The B<before> advice declaration is used to defined advice code that will be
run instead of the code originally at the join points, but continuing on to the
real function if no action is taken to say otherwise.

When called in void context, as shown above, C<before> will install the advice
permanently into your program.

When called in scalar context, as shown below, C<before> will return a guard
object and enable the advice for as long as that guard object continues to
remain in scope or otherwise avoid being destroyed.

  SCOPE: {
      my $guard = before {
          print "Hello World!\n";
      } call 'My::foo';
  
      # This will print
      My::foo(); 
  }
  
  # This will NOT print
  My::foo();

Because the end result of the code at the join points is irrelevant to this
type of advice and the Aspect system does not need to hang around and maintain
control during the join point, the underlying implementation is done in a way
that is by far the fastest and with the least impact (essentially none) on the
execution of your program.

You are B<strongly> encouraged to use C<before> advice wherever possible for the
current implementation, resorting to the other advice types when you truly need
to be there are the end of the join point execution (or on both sides of it).

=cut

sub before (&$) {
	Aspect::Advice::Before->new(
		code     => $_[0],
		pointcut => $_[1],
		lexical  => defined wantarray,
	);
}

sub around (&$) {
	Aspect::Advice::Around->new(
		code     => $_[0],
		pointcut => $_[1],
		lexical  => defined wantarray,
	);
}

sub after (&$) {
	Aspect::Advice::After->new(
		code     => $_[0],
		pointcut => $_[1],
		lexical  => defined wantarray,
	);
}

sub after_returning (&$) {
	Aspect::Advice::AfterReturning->new(
		code     => $_[0],
		pointcut => $_[1],
		lexical  => defined wantarray,
	);
}

sub after_throwing (&$) {
	Aspect::Advice::AfterThrowing->new(
		code     => $_[0],
		pointcut => $_[1],
		lexical  => defined wantarray,
	);
}

sub aspect {
	my $class = _LIBRARY(shift);
	return $class->new(
		lexical => defined wantarray,
		params  => [ @_ ],
	);
}






######################################################################
# Import Logic

sub import {
	my $class  = shift;
	my $legacy = 0;
	my $into   = caller();
	while ( @_ ) {
		my $value = shift;
		if ( $value eq ':legacy' ) {
			$legacy = 1;
		} else {
			Carp::croak("Unknown or unsupported import param '$value'");
		}
	}

	# Install unchanged legacy functions
	foreach ( qw{ aspect before call cflow } ) {
		Sub::Install::install_sub( {
			code => $_,
			into => $into,
		} );
		$EXPORTED{"${into}::$_"} = 1;
	}

	# Install functions that change between API versions
	Sub::Install::install_sub( {
		code => $legacy ? 'after_returning' : 'after',
		as   => 'after',
		into => $into,
	} );
	$EXPORTED{"${into}::after"} = 1;

	unless ( $legacy ) {
		# Install new generation API functions
		foreach ( qw{
			around after_returning after_throwing
			if_true highest throwing
			wantlist wantscalar wantvoid
		} ) {
			Sub::Install::install_sub( {
				code => $_,
				into => $into,
			} );
			$EXPORTED{"${into}::$_"} = 1;
		}
	}

	return 1;
}





######################################################################
# Private Functions

# Run-time use call
# NOTE: Do we REALLY need to do this as a use?
#       If the ->import method isn't important, change to native require.
sub _LIBRARY {
	my $package = shift;
	if ( Params::Util::_IDENTIFIER($package) ) {
		$package = "Aspect::Library::$package";
	}
	Params::Util::_DRIVER($package, 'Aspect::Library');
}

1;

=pod

=head2 Advice

An advice definition is just some code that will run on a match of some
pointcut. The C<advice> can run around the entire call to allow
lexical variables to capture custom information on the way into the function
that will be needed when it exists, or it can be more specific and only run
before the sub, after the sub runs and returns, after the sub throws an
exception, or after the sub runs regardless of the result.

Using a more specific advice type will allow the optimiser to generate
smaller and faster hooks into your code.

You create advice using C<around>, C<before>, C<after_returning>,
C<after_throwing> or C<after()>.

These take a C<CODE> ref, and a pointcut, and install the code on the subs
that match the pointcut.  For example:

  after {
      print "Person::get_address has returned!\n";
  } call 'Person::get_address';

The advice code is run with one parameter: the advice context. You use it to
learn how the matched sub was run, modify parameters, return value, and if it
is run at all.

When the advice is created in void context, it remains enabled until the
interpreter dies, or the symbol table reloaded.

However, advice code can also be applied to matching pointcuts
(i.e. the advice is enabled) for only a specific scope by declare it in
scalar context and storing the returned guard object.

This allows you to neatly control enabling and disabling of advice:

  SCOPE: {
     my $advice = before { print "called!\n" } $pointcut;
  
     # Do something while the device is enabled
  }
  
  # The advice is now disabled

Please note that due to the internal mechanism used to achieve this lexical
scoping, you may see a slight loss of memory and a slight slow down of the
function, even after the advice has gone out of scope.

Lexically creating and removing advice many times is recommended against,
and doing so hundreds or thousands of times may result in significant
memory consumption of performance loss for the functions matched by your
pointcut.

=head2 Aspects

Aspects are just plain old Perl objects, that install advice, and do
other AOP-like things, like install methods on other classes, or mess around
with the inheritance hierarchy of other classes. A good base class for them
is L<Aspect::Modular>, but you can use any Perl object as long as the class
inherits from L<Aspect::Library>.

If the aspect class exists immediately below the namespace
C<Aspect::Library>, then it can be easily created with the following
shortcut.

  aspect Singleton => 'Company::create';

This will create an L<Aspect::Library::Singleton> object. This reusable
aspect is included in the B<Aspect> distribution, and forces singleton
behavior on some constructor, in this case, C<Company::create()>.

Such aspects share a similar behaviour to advice. If enabled in void context
they will be installed permanently, but if called in scalar context they
will return a guard object that allows the aspect to be enabled only until
the end of the current scope.

=head2 Internals

Due to the dynamic nature of Perl, there is no need for processing of source
or byte code, as required in the Java and .NET worlds.

The implementation is very simple: when you create advice, its pointcut is
matched using C<match_define()> to find every sub defined in the symbol
table that might match against the pointcut (potentially subject to further
runtime conditions).

Those that match, will get a special wrapper installed. The wrapper only
executes if, during run-time, a compiled context test for the pointcut
returns true.

The wrapper code creates an advice context, and gives it to the advice code.

Some pointcuts like C<call()> are static, so the compiled run-time function
always returns true, and C<match_define()> returns true if the sub name
matches the pointcut spec.

Some pointcuts like C<cflow()> are dynamic, so C<match_define()> always
returns true, but the compiled run-time function returns true only if some
condition within the point is true.

To make this process faster, when the advice is installed, the pointcut
will not use itself directly for the compiled run-time function but will
additionally generate a "curried" (optimised) version of itself.

This curried version uses the fact that the run-time check will only be
called if it matches the C<call()> pointcut pattern, and so no C<call()>
pointcuts needed to be tested at run-time unless they are in deep and
complex nested coolean logic. It also handles collapsing any boolean logic
impacted by the safe removal of the C<call()> pointcuts.

If you use only C<call()> pointcuts (alone or in boolean combinations)
the currying results in a null test (the pointcut is optimised away
entirely) and so the need to make a run-time point test will be removed
altogether from the generated advice hooks, reducing call overheads
significantly.

If your pointcut does not have any static conditions (i.e. C<call>) then
the wrapper code will need to be installed into every function on the symbol
table. This is highly discouraged and liable to result in hooks on unusual
functions and unwanted side effects.

=head1 FUNCTIONS

TO BE COMPLETED

=head1 LIMITATIONS

=head2 Inheritance Support

Support for inheritance is lacking. Consider the following two classes:

  package Automobile;
  ...
  sub compute_mileage { ... }
  
  package Van;
  use base 'Automobile';

And the following two advice:

  before { print "Automobile!\n" } call 'Automobile::compute_mileage';
  before { print "Van!\n"        } call 'Van::compute_mileage';

Some join points one would expect to be matched by the call pointcuts
above, do not:

  $automobile = Automobile->new;
  $van = Van->new;
  $automobile->compute_mileage; # Automobile!
  $van->compute_mileage;        # Automobile!, should also print Van!

C<Van!> will never be printed. This happens because B<Aspect> installs
advice code on symbol table entries. C<Van::compute_mileage> does not
have one, so nothing happens. Until this is solved, you have to do the
thinking about inheritance yourself.

=head2 Performance

You may find it very easy to shoot yourself in the foot with this module.
Consider this advice:

  # Do not do this!
  before {
      print $_->sub_name;
  } cflow 'MyApp::Company::make_report';

The advice code will be installed on B<every> sub loaded. The advice code
will only run when in the specified call flow, which is the correct
behavior, but it will be I<installed> on every sub in the system. This
can be slow. It happens because the C<cflow()> pointcut matches I<all>
subs during weave-time. It matches the correct sub during run-time. The
solution is to narrow the pointcut:

  # Much better
  before {
      print $_->sub_name;
  } call qr/^MyApp::/
  & cflow 'MyApp::Company::make_report';

=head1 TO DO

There are a number of things that could be added, if people have an interest
in contributing to the project.

=head1 Documentation

* cookbook

* tutorial

* example of refactoring a useful CPAN module using aspects

=head2 Pointcuts

* new pointcuts: execution, cflowbelow, within, advice, calledby. Sure
  you can implement them today with Perl treachery, but it is too much
  work.

* need a way to match subs with an attribute, attributes::get()
  will not work for some reason

* isa() support for method pointcuts as Gaal Yahas suggested: match
  methods on class hierarchies without callbacks

* Perl join points: phasic- BEGIN/INIT/CHECK/END 

* The previous items indicate a need for a real join point specification
  language

=head2 Weaving

* look into byte code manipulation with B:: modules- could be faster, no
  need to mess with caller, and could add many more pointcut types. All
  we need to do for sub pointcuts is add 2 gotos to selected subs.

* a debug flag to print out subs that were matched on match_define

* warnings when over 1000 methods wrapped

* support more pulling (vs. pushing) of aspects into packages:
  attributes, package specific join points
 
* add whatever constructs required for mocking packages, objects,
  builtins

* allow finer control of advice execution order

=head2 Reusable Aspects

* need better example for wormhole- something less tedius

* use Scalar-Footnote for adding aspect state to objects, e.g. in
  Listenable. Problem is it is still in developer release state

* Listenable: when listeners go out of scope, they should be removed from
  listenables, so you don't have to remember to remove them manually

* Listenable: should overload some operator on listenables so that it is 
  easier to add/remove listeners, e.g.:
    $button += (click => sub { print 'click!' });

* design aspects: DBC, threading, more GOF patterns

* middleware aspects: security, load balancing, timeout/retry, distribution

* Perl aspects: add use strict/warning/Carp to all matched packages.
  Actually, Spiffy, Toolkit, and Toolset do this already very nicely.

* interface with existing Perl modules for logging, tracing, param
  checking, generally all things that are AOPish on CPAN. One should
  be able to use it all through one consistent interface. If I have a
  good set of pointcuts, I should be able to do all kinds of cross-
  cutting things with them.

* UnderscoreContext aspect: subs that match will, if called with no
  parameters, get $_, and if in void context, return value will set $_.
  Allows you to use your subs like builtins, that fall back on $_. So if
  we have a sub:

     sub replace_foo { my $in = shift; $in =~ s/foo/bar; $in }

  Then both calls would be equivalent:

     $_ = replace_foo($_);
     replace_foo;

* a generic FriendParamAppender aspect, that adds to a param list
  for affected methods, any object the method requires. Heuristics
  are applied to find the friend: maybe it is available in the call
  flow? Perhaps someone in the call flow has an accessor that can
  get it? Maybe a lexical in some sub in the call flow has it? The
  point is to cover all cases where we pass objects around, so that
  we don't have to. A generalization of the wormhole aspect.

=head1 SUPPORT

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Aspect>.

=head1 INSTALLATION

See L<perlmodinstall> for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see L<http://search.cpan.org/perldoc?Aspect.pm>.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 SEE ALSO

You can find AOP examples in the C<examples/> directory of the
distribution.

L<Aspect::Library::Memoize>

L<Aspect::Library::Profiler>

L<Aspect::Library::Trace>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2011 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
