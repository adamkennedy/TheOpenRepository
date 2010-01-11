package Aspect;

use 5.008002;
use strict;
use warnings;

# Added by eilara as hack around caller() core dump
# NOTE: Now we've switched to Sub::Uplevel can this be removed?
# -- ADAMK
use Carp::Heavy ();
use Carp        ();

# NOTE: According to the Sub::UpLevel docs, we should load it before
# we load Exporter. But that's a pretty difficult thing.
# So we'll do the best we can here, and then in the future we might
# want to consider switching to "use Sub::UpLevel ':aggressive';"
# -- ADAMK
use Sub::Uplevel                   ();
use Exporter                       ();
use Aspect::Advice                 ();
use Aspect::AdviceContext          ();
use Aspect::Advice::Around         ();
use Aspect::Advice::Before         ();
use Aspect::Advice::After          ();
use Aspect::Advice::AfterReturning ();
use Aspect::Advice::AfterThrowing  ();
use Aspect::Pointcut               ();
use Aspect::Pointcut::Call         ();
use Aspect::Pointcut::Cflow        ();
use Aspect::Pointcut::AndOp        ();
use Aspect::Pointcut::OrOp         ();
use Aspect::Pointcut::NotOp        ();

our $VERSION = '0.35';
our @ISA     = 'Exporter';
our @EXPORT  = qw{
	aspect
	around
	before
	after
	after_returning
	after_throwing
	call
	cflow
};

# Internal data storage
my @FOREVER = ();





######################################################################
# Public (Exported) Functions

sub aspect {
	my $class  = _LOAD('Aspect::Library::' . shift);
	my $aspect = $class->new(
		lexical => defined wantarray,
		params  => [ @_ ],
	);

	# If called in void context, aspect is for life
	push @FOREVER, $aspect unless defined wantarray;

	return $aspect;
}

sub around (&$) {
	Aspect::Advice::Around->new(
		code     => $_[0],
		pointcut => $_[1],
		lexical  => defined wantarray,
	);
}

sub before (&$) {
	Aspect::Advice::Before->new(
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

sub call ($) {
	Aspect::Pointcut::Call->new(@_);
}

sub cflow ($$) {
	Aspect::Pointcut::Cflow->new(@_);
}





######################################################################
# Private Functions

# Run-time use call
# NOTE: Do we REALLY need to do this as a use?
#       If the ->import method isn't important, change to native require.
sub _LOAD {
	my $package = shift;
	eval "require $package;";
	Carp::croak("Cannot use [$package]: $@") if $@;
	return $package;
}

1;

__END__

=pod

=head1 NAME

Aspect - Aspect-Oriented Programming (AOP) for Perl

=head1 SYNOPSIS

  package Person;
  
  sub create      { ... }
  
  sub set_name    { ... }
  
  sub get_address { ... }
  
  package main;
  
  use Aspect;
  
  # Using reusable aspects
  aspect Singleton => 'Person::create';        # let there be only one Person
  aspect Profiler  => call qr/^Person::set_/;  # profile calls to setters
  
  # Append extra argument when Person::get_address is called:
  # the instance of the calling Company object, iff get_address
  # is in the call flow of Company::get_employee_addresses.
  # aspect will live as long as $wormhole reference is in scope
  $aspect = aspect Wormhole => 'Company::make_report', 'Person::get_address';
  
  # Writing your own advice
  $pointcut = call qr/^Person::[gs]et_/; # defines a collection of events
  
  # Advice will live as long as $before is in scope
  $before = before {
      print "g/set will soon be called";
  } $pointcut;
  
  # Advice will live lexical, because it is created in void context 
  after {
      print "g/set has just been called";
  } $pointcut;
  
  before {
      print "get will soon be called, if in call flow of Tester::run_tests";
  } call qr/^Person::get_/
  & cflow tester => 'Tester::run_tests';
  
  # Conditionally hijack a method if some condition is true
  around {
      my $context = shift;
      if ( $context->self->customer_name eq 'Adam Kennedy' ) {
          $context->return_value('One meeeelion dollars');
      } else {
          # Take a dollar off everyone else
          $context->run_original;
          $context->return_value( $context->return_value - 1 );
      }
  } call 'Bank::Account::balance';

=head1 DESCRIPTION

Aspect-Oriented Programming (AOP) is a programming method developed by Xerox
PARC and others. The basic idea is that in complex class systems there are
certain aspects or behaviors that cannot normally be expressed in a coherent,
concise and precise way. One example of such aspects are design
patterns, which combine various kinds of classes to produce a common
type of behavior. Another is logging. See L<http://www.aosd.net> for
more info.

The Perl C<Aspect> module closely follows the terminology of the AspectJ
project (L<http://eclipse.org/aspectj>). However due to the dynamic nature of
the Perl language, several C<AspectJ> features are useless for us: exception
softening, mixin support, out-of-class method declarations, and others.

The Perl C<Aspect> module is focused on subroutine matching and wrapping.  It
allows you to select collections of subroutines using a flexible pointcut
language, and modify their behavior in any way you want.

=head1 TERMINOLOGY 

=over

=item Join Point

An event that occurs during the running of a program. Currently only calls to
subroutines are recognized as join points.

=item Pointcut

An expression that selects a collection of join points. For example: all calls
to the class C<Person>, that are in the call flow of some C<Company>, but
I<not> in the call flow of C<Company::make_report>.  C<Aspect> supports
C<call()>, and C<cflow()> pointcuts, and logical operators (C<&>, C<|>, C<!>)
for constructing more complex pointcuts. See the L<Aspect::Pointcut>
documentation.

=item Advice

A pointcut, with code that will run when it matches. The code can be run
before or after the matched sub is run.

=item Advice Code

The code that is run before or after a pointcut is matched. It can modify the
way that the matched sub is run, and the value it returns.

=item Weave

The installation of advice code on subs that match a pointcut. Weaving
happens when you create the advice. Unweaving happens when the advice
goes out of scope.

=item The Aspect

An object that installs advice. A way to package advice and other Perl code,
so that it is reusable.

=back

=head1 FEATURES

=over

=item *

Create and remove pointcuts, advice, and aspects.

=item *

Flexible pointcut language: select subs to match using string equality,
regexp, or C<CODE> ref. Match currently running sub, or a sub in the call
flow. Build pointcuts composed of a logical expression of other pointcuts,
using conjunction, disjunction, and negation.

=item *

In advice code, you can: modify parameter list for matched sub, modify return
value, decide if to proceed to matched sub, access C<CODE> ref for matched
sub, and access the context of any call flow pointcuts that were matched, if
they exist.

=item *

Add/remove advice and entire aspects during run-time. Scope of advice and
aspect objects, is the scope of their effect.

=item *

A reusable aspect library. The L<Wormhole|Aspect::Library::Wormhole>, aspect,
for example. A base class makes it easy to create your own reusable aspects.
The L<Memoize|Aspect::Library::Memoize> aspect is an example of how to
interface with AOP-like modules from CPAN.

=back

=head1 WHY

Perl is a highly dynamic language, where everything this module does can be
done without too much difficulty. All this module does, is make it even
easier, and bring these features under one consistent interface. I have found
it useful in my work in several places:

=over

=item *

Saves me from typing an entire line of code for almost every C<Test::Class>
test method, because I use the L<TestClass|Aspect::Library::TestClass> aspect.

=item *

I use the L<Wormhole|Aspect::Library::Wormhole> aspect, so that my methods can
acquire implicit context, and so I don't need to pass too many parameters all
over the place. Sure I could do it with C<caller()> and C<Hook::LexWrap>, but
this is much easier.

=item *

Using custom advice to modify class behavior: register objects when
constructors are called, save object state on changes to it, etc. All this,
while cleanly separating these concerns from the effected class. They exist
as an independent aspect, so the class remains unpolluted.

=back

The C<Aspect> module is different from C<Hook::Lexwrap> (which it uses for the
actual wrapping) in two respects:

=over

=item *

Select join points using flexible pointcut language instead of the sub name.
For example: select all calls to C<Account> objects that are in the call flow
of C<Company::make_report>.

=item *

More options when writing the advice code. You can, for example, run the
original sub, or append parameters to it.

=back

=head1 USING

This package is a facade on top of the Perl AOP framework. It allows you to
create pointcuts, advice, and aspects. You will be mostly working with this
package (C<Aspect>), and the L<advice context|Aspect::AdviceContext> package.

When you use this package:

use Aspect;

You will import five subs: C<call()>, C<cflow()>, C<before()>, C<after()>, and
C<aspect()>. These are all factories that allow you to create pointcuts,
advice, and aspects.

=head2 POINTCUTS

Pointcuts select join points, so that an advice can run code when they happen.
The simplest pointcut is C<call()>. For example:

  $p = call 'Person::get_address';

Selects the calling of C<Person::get_address()>, as defined in the symbol
table during weave-time. The string is a pointcut spec, and can be expressed
in three ways:

=over

=item C<string>

Select only the sub whose name is equal to the spec string.

=item C<regexp>

Select only the subs whose name matches the regexp. The following will match
all the subs defined on the C<Person> class, but not on the C<Person::Address>
class.

  $p = call qr/^Person::\w+$/;

=item C<CODE> ref

Select only subs, where the supplied code, when run with the sub name as only
parameter, returns true. The following will match all calls to subs whose name
isa key in the hash C<%subs_to_match>:

  $p = call sub { exists $subs_to_match{shift()} }

=back

Pointcuts can be combined to form logical expressions, because they overload
C<&>, C<|>, and C<!>, with factories that create composite pointcut objects.
Be careful not to use the non-overloadable C<&&>, and C<||> operators, because
you will get no error message.

Select all calls to C<Person>, which are not calls to the constructor:

  $p = call qr/^Person::\w+$/ & !call 'Person::create';

The second pointcut you can use, is C<cflow()>. It selects only the subs that
are in call flow of its spec. Here we select all calls to C<Person>, only if
they are in the call flow of some method in C<Company>:

  $p = call qr/^Person::\w+$/ & cflow company => qr/^Company::\w+$/;

The C<cflow()> pointcut takes two parameters: a context key, and a pointcut
spec. The context key is used in advice code to access the context (params,
sub name, etc.) of the sub found in the call flow. In the example above, the
key can be used to access the name of the specific sub on C<Company> that was
found in the call flow of the C<Person> method.The second parameter is a
pointcut spec, that should match the sub required from the call flow.

See the L<Aspect::Pointcut> docs for more info.

=head2 ADVICE

An advice is just some definition of code that will run on a match of some
pointcut. An advice can run before the pointcut matched sub is run, or after.
You create advice using C<before()>, C<after()>, or C<around()>.
These take a C<CODE> ref, and a pointcut, and install the code on the subs
that match the pointcut.  For example:

  after {
      print "Person::get_address has returned!\n";
  } call 'Person::get_address';

The advice code is run with one parameter: the advice context. You use it to
learn how the matched sub was run, modify parameters, return value, and if it
is run at all. You also use the advice context to access any context objects
that were created by any matching C<cflow()> pointcuts.  This will print the
name of the C<Company> that started the call flow which eventually reached
C<Person::get_address()>:

  before {
      print shift->company->name;
  } call 'Person::get_address'
  & cflow company => qr/^Company::w+$/;

See the L<Aspect::AdviceContext> docs for some more examples of advice code.

Advice code is applied to matching pointcuts (i.e. the advice is enabled) as
long as the advice object is in scope. This allows you to neatly control
enabling and disabling of advice:

  SCOPE: {
     my $advice = before { print "called!\n" } $pointcut;
     # do something while the device is enabled
  }
  # the advice is now disabled

If the advice is created in void context, it remains enabled until the
interpreter dies, or the symbol table reloaded.

=head2 ASPECTS

Aspects are just plain old Perl objects, that install advice, and do
other AOP-like things, like install methods on other classes, or mess around
with the inheritance hierarchy of other classes. A good base class for them is
L<Aspect::Modular>, but you can use any Perl object.

If the aspect class exists in the package C<Aspect::Library>, then it can be
easily created:

  aspect Singleton => 'Company::create';

Will create an L<Aspect::Library::Singleton> object. This reusable aspect is
included in the C<Aspect> distribution, and forces singleton behavior on some
constructor, in this case, C<Company::create()>.

Such aspects, like advice, are enabled as long as they are in scope.

=head1 INTERNALS

Due to the dynamic nature of Perl, there is no need for processing of source
or byte code, as required in the Java and .NET worlds.

The implementation is very simple: when you create advice, its pointcut is
matched using C<match_define()>. Every sub defined in the symbol table is
matched against the pointcut. Those that match, will get a special wrapper
installed. The wrapper only runs if during run-time, the C<match_run()> of
the pointcut returns true.

The wrapper code creates an advice context, and gives it to the advice code.

The C<call()> pointcut is static, so C<match_run()> always returns true,
and C<match_define()> returns true if the sub name matches the pointcut
spec.

The C<cflow()> pointcut is dynamic, so C<match_define()> always returns
true, but C<match_run()> return true only if some frame in the call flow
matches the pointcut spec.

To make this process faster, when the advice is installed, the pointcut
will not use itself directly for the C<match_run()> but will generate
a "curried" (optimised) version of itself. This curried version uses the
fact that C<match_run()> will only be called if it matches the C<call()>
pointcut pattern, and so no C<call()> pointcuts needed to be tested at
run-time. It also handles collapsing any boolean logic impacted by the
removal of the C<call()> pointcuts.

If you use only C<call()> pointcuts (alone or in boolean combinations)
the currying results in a null case (the pointcut is optimised away
entirely) and so the call to C<match_run()> will be removed altogether
from the generated advice hooks, reducing the overhead significantly.

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

C<Van!> will never be printed. This happens because C<Aspect> installs
advice code on symbol table entries. C<Van::compute_mileage> does not
have one, so nothing happens. Until this is solved, you have to do the
thinking about inheritance yourself.

=head2 Performance

You may find it very easy to shoot yourself in the foot with this module.
Consider this advice:

  # Do not do this!
  before {
      print shift->sub_name;
  } cflow company => 'MyApp::Company::make_report';

The advice code will be installed on B<every> sub loaded. The advice code
will only run when in the specified call flow, which is the correct
behavior, but it will be I<installed> on every sub in the system. This
can be slow. It happens because the C<cflow()> pointcut matches I<all>
subs during weave-time. It matches the correct sub during run-time. The
solution is to narrow the pointcut:

  # Much better
  before {
      print shift->sub_name;
  } call qr/^MyApp::/
  & cflow company => 'MyApp::Company::make_report';

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

* debugger support: break on pointcut

* allow finer control of advice execution order

=head2 Reusable Aspects

* need better example for wormhole- something less tedius

* bring back Marcel's tracing aspect and example, class invariants
  example

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
site near you. Or see L<http://search.cpan.org/perldoc?Aspsect.pm>.

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

=head1 COPYRIGHT AND LICENSE

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2010 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
