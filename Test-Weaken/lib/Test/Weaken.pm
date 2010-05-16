package Test::Weaken;

use strict;
use warnings;

require Exporter;

use base qw(Exporter);
our @EXPORT_OK = qw(leaks poof);
our $VERSION   = '3.004000';

# use Smart::Comments;

### <where> Using Smart Comments ...

## no critic (BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

=begin Implementation:

The basic strategy: get a list of all the objects which allocate memory,
create probe references to them, weaken those probe references, attempt
to free the memory, and check the references.  If the memory is free,
the probe references will be undefined.

Probe references also serve a second purpose -- to avoid copying any
weak reference in the original object.  When you copy a weak reference,
the result is a strong reference.

There may be good reasons for Perl strengthen-on-copy policy, but that
behavior is a big problem for this module.  A lot of what might seem
like needless indirection in the code below is done to avoid working
with references directly in situations which could involve making a copy
of them, even implicitly.

=end Implementation:

=cut

package Test::Weaken::Internal;

use English qw( -no_match_vars );
use Carp;
use Scalar::Util 1.18 qw();

my @default_tracked_types = qw(REF SCALAR VSTRING HASH ARRAY CODE);

sub follow {
    my ( $self, $base_probe ) = @_;

    my $ignore             = $self->{ignore};
    my $contents           = $self->{contents};
    my $trace_maxdepth     = $self->{trace_maxdepth};
    my $trace_following    = $self->{trace_following};
    my $trace_tracking     = $self->{trace_tracking};
    my $user_tracked_types = $self->{tracked_types};

    my @tracked_types = @default_tracked_types;
    if ( defined $user_tracked_types ) {
        push @tracked_types, @{$user_tracked_types};
    }
    my %tracked_type = map { ( $_, 1 ) } @tracked_types;

    defined $trace_maxdepth or $trace_maxdepth = 0;

    # Initialize the results with a reference to the dereferenced
    # base reference.

    # The initialization assumes the $base_probe is a reference,
    # not part of the test object, whose referent is also a reference
    # which IS part of the test object.
    my @follow_probes    = ($base_probe);
    my @tracking_probes  = ($base_probe);
    my %already_followed = ();
    my %already_tracked  = ();

    FOLLOW_OBJECT:
    while ( defined( my $follow_probe = pop @follow_probes ) ) {

        # The follow probes are to objects which either will not be
        # tracked or which have already been added to @tracking_probes

        next FOLLOW_OBJECT
            if $already_followed{ Scalar::Util::refaddr $follow_probe }++;

        my $object_type = Scalar::Util::reftype $follow_probe;

        my @child_probes = ();

        if ($trace_following) {
            ## no critic (ValuesAndExpressions::ProhibitLongChainsOfMethodCalls)
            print {*STDERR} 'Following: ',
                Data::Dumper->new( [$follow_probe], [qw(tracking)] )->Terse(1)
                ->Maxdepth($trace_maxdepth)->Dump
                or Carp::croak("Cannot print to STDOUT: $ERRNO");
            ## use critic
        } ## end if ($trace_following)

        if ( defined $contents ) {
            my $safe_copy = $follow_probe;
            push @child_probes, map { \$_ } ( $contents->($safe_copy) );
        }

        FIND_CHILDREN: {

            if ( defined $ignore ) {
                my $safe_copy = $follow_probe;
                last FIND_CHILDREN if $ignore->($safe_copy);
            }

            if ( $object_type eq 'ARRAY' ) {
                if ( my $tied_var = tied @{$follow_probe} ) {
                    push @child_probes, \($tied_var);
                }
                foreach my $i ( 0 .. $#{$follow_probe} ) {
                    if ( exists $follow_probe->[$i] ) {
                        push @child_probes, \( $follow_probe->[$i] );
                    }
                }
                last FIND_CHILDREN;
            } ## end if ( $object_type eq 'ARRAY' )

            if ( $object_type eq 'HASH' ) {
                if ( my $tied_var = tied %{$follow_probe} ) {
                    push @child_probes, \($tied_var);
                }
                push @child_probes, map { \$_ } values %{$follow_probe};
                last FIND_CHILDREN;
            } ## end if ( $object_type eq 'HASH' )

            # GLOB and LVALUE are not tracked by default,
            # but we follow ties
            if (   $object_type eq 'SCALAR'
                or $object_type eq 'GLOB'
                or $object_type eq 'VSTRING'
                or $object_type eq 'LVALUE' )
            {
                if ( my $tied_var = tied ${$follow_probe} ) {
                    push @child_probes, \($tied_var);
                }
                last FIND_CHILDREN;
            } ## end if ( $object_type eq 'SCALAR' or $object_type eq 'GLOB'...)

            if ( $object_type eq 'REF' ) {
                if ( my $tied_var = tied ${$follow_probe} ) {
                    push @child_probes, \($tied_var);
                }
                push @child_probes, ${$follow_probe};
                last FIND_CHILDREN;
            } ## end if ( $object_type eq 'REF' )

        } ## end FIND_CHILDREN:

        push @follow_probes, @child_probes;

        CHILD_PROBE: for my $child_probe (@child_probes) {

            my $child_type = Scalar::Util::reftype $child_probe;

            next CHILD_PROBE unless $tracked_type{$child_type};

            my $new_tracking_probe = $child_probe;

            next CHILD_PROBE
                if $already_tracked{ Scalar::Util::refaddr $new_tracking_probe
                    }++;

            if ( defined $ignore ) {
                my $safe_copy = $new_tracking_probe;
                next CHILD_PROBE if $ignore->($safe_copy);
            }

            if ($trace_tracking) {
                ## no critic (ValuesAndExpressions::ProhibitLongChainsOfMethodCalls)
                print {*STDERR} 'Tracking: ',
                    Data::Dumper->new( [$new_tracking_probe], [qw(tracking)] )
                    ->Terse(1)->Maxdepth($trace_maxdepth)->Dump
                    or Carp::croak("Cannot print to STDOUT: $ERRNO");
                ## use critic
            } ## end if ($trace_tracking)
            push @tracking_probes, $new_tracking_probe;

        } ## end for my $child_probe (@child_probes)

    }    # FOLLOW_OBJECT

    return \@tracking_probes;

}    # sub follow

# See POD, below
sub Test::Weaken::new {
    my ( $class, $arg1, $arg2 ) = @_;
    my $constructor;
    my $destructor;
    my $self = {};
    bless $self, $class;
    $self->{test} = 1;

    UNPACK_ARGS: {
        if ( ref $arg1 eq 'CODE' ) {
            $self->{constructor} = $arg1;
            if ( defined $arg2 ) {
                $self->{destructor} = $arg2;
            }
            return $self;
        }

        if ( ref $arg1 ne 'HASH' ) {
            Carp::croak('arg to Test::Weaken::new is not HASH ref');
        }

        if ( defined $arg1->{constructor} ) {
            $self->{constructor} = $arg1->{constructor};
            delete $arg1->{constructor};
        }

        if ( defined $arg1->{destructor} ) {
            $self->{destructor} = $arg1->{destructor};
            delete $arg1->{destructor};
        }

        if ( defined $arg1->{ignore} ) {
            $self->{ignore} = $arg1->{ignore};
            delete $arg1->{ignore};
        }

        if ( defined $arg1->{trace_maxdepth} ) {
            $self->{trace_maxdepth} = $arg1->{trace_maxdepth};
            delete $arg1->{trace_maxdepth};
        }

        if ( defined $arg1->{trace_following} ) {
            $self->{trace_following} = $arg1->{trace_following};
            delete $arg1->{trace_following};
        }

        if ( defined $arg1->{trace_tracking} ) {
            $self->{trace_tracking} = $arg1->{trace_tracking};
            delete $arg1->{trace_tracking};
        }

        if ( defined $arg1->{contents} ) {
            $self->{contents} = $arg1->{contents};
            delete $arg1->{contents};
        }

        if ( defined $arg1->{test} ) {
            $self->{test} = $arg1->{test};
            delete $arg1->{test};
        }

        if ( defined $arg1->{tracked_types} ) {
            $self->{tracked_types} = $arg1->{tracked_types};
            delete $arg1->{tracked_types};
        }

        my @unknown_named_args = keys %{$arg1};

        if (@unknown_named_args) {
            my $message = q{};
            for my $unknown_named_arg (@unknown_named_args) {
                $message .= "Unknown named arg: '$unknown_named_arg'\n";
            }
            Carp::croak( $message
                    . 'Test::Weaken failed due to unknown named arg(s)' );
        }

    }    # UNPACK_ARGS

    if ( my $ref_type = ref $self->{constructor} ) {
        Carp::croak('Test::Weaken: constructor must be CODE ref')
            unless ref $self->{constructor} eq 'CODE';
    }

    if ( my $ref_type = ref $self->{destructor} ) {
        Carp::croak('Test::Weaken: destructor must be CODE ref')
            unless ref $self->{destructor} eq 'CODE';
    }

    if ( my $ref_type = ref $self->{ignore} ) {
        Carp::croak('Test::Weaken: ignore must be CODE ref')
            unless ref $self->{ignore} eq 'CODE';
    }

    if ( my $ref_type = ref $self->{contents} ) {
        Carp::croak('Test::Weaken: contents must be CODE ref')
            unless ref $self->{contents} eq 'CODE';
    }

    if ( my $ref_type = ref $self->{tracked_types} ) {
        Carp::croak('Test::Weaken: tracked_types must be ARRAY ref')
            unless ref $self->{tracked_types} eq 'ARRAY';
    }

    return $self;

}    # sub new

sub Test::Weaken::test {

    my $self = shift;

    if ( defined $self->{unfreed_probes} ) {
        Carp::croak('Test::Weaken tester was already evaluated');
    }

    my $constructor = $self->{constructor};
    my $destructor  = $self->{destructor};
    my $ignore      = $self->{ignore};
    my $contents    = $self->{contents};
    my $test        = $self->{test};

    my $test_object_probe = \( $constructor->() );
    if ( not ref ${$test_object_probe} ) {
        Carp::carp(
            'Test::Weaken test object constructor did not return a reference'
        );
    }
    my $probes = Test::Weaken::Internal::follow( $self, $test_object_probe );

    $self->{probe_count} = @{$probes};
    $self->{weak_probe_count} =
        grep { ref $_ eq 'REF' and Scalar::Util::isweak ${$_} } @{$probes};
    $self->{strong_probe_count} =
        $self->{probe_count} - $self->{weak_probe_count};

    if ( not $test ) {
        $self->{unfreed_probes} = $probes;
        return scalar @{$probes};
    }

    for my $probe ( @{$probes} ) {
        Scalar::Util::weaken($probe);
    }

    # Now free everything.
    $destructor->( ${$test_object_probe} ) if defined $destructor;

    $test_object_probe = undef;

    my $unfreed_probes = [ grep { defined $_ } @{$probes} ];
    $self->{unfreed_probes} = $unfreed_probes;

    return scalar @{$unfreed_probes};

}    # sub test

# Undocumented and deprecated
sub poof_array_return {

    my $tester  = shift;
    my $results = $tester->{unfreed_probes};

    my @unfreed_strong = ();
    my @unfreed_weak   = ();
    for my $probe ( @{$results} ) {
        if ( ref $probe eq 'REF' and Scalar::Util::isweak ${$probe} ) {
            push @unfreed_weak, $probe;
        }
        else {
            push @unfreed_strong, $probe;
        }
    }

    return (
        $tester->weak_probe_count(),
        $tester->strong_probe_count(),
        \@unfreed_weak, \@unfreed_strong
    );

} ## end sub poof_array_return;

# Undocumented and deprecated
sub Test::Weaken::poof {
    my @args   = @_;
    my $tester = Test::Weaken->new(@args);
    my $result = $tester->test();
    return Test::Weaken::Internal::poof_array_return($tester) if wantarray;
    return $result;
}

sub Test::Weaken::leaks {
    my @args   = @_;
    my $tester = Test::Weaken->new(@args);
    my $result = $tester->test();
    return $tester if $result;
    return;
}

sub Test::Weaken::unfreed_proberefs {
    my $tester = shift;
    my $result = $tester->{unfreed_probes};
    if ( not defined $result ) {
        Carp::croak('Results not available for this Test::Weaken object');
    }
    return $result;
}

sub Test::Weaken::unfreed_count {
    my $tester = shift;
    my $result = $tester->{unfreed_probes};
    if ( not defined $result ) {
        Carp::croak('Results not available for this Test::Weaken object');
    }
    return scalar @{$result};
}

sub Test::Weaken::probe_count {
    my $tester = shift;
    my $count  = $tester->{probe_count};
    if ( not defined $count ) {
        Carp::croak('Results not available for this Test::Weaken object');
    }
    return $count;
}

# Undocumented and deprecated
sub Test::Weaken::weak_probe_count {
    my $tester = shift;
    my $count  = $tester->{weak_probe_count};
    if ( not defined $count ) {
        Carp::croak('Results not available for this Test::Weaken object');
    }
    return $count;
}

# Undocumented and deprecated
sub Test::Weaken::strong_probe_count {
    my $tester = shift;
    my $count  = $tester->{strong_probe_count};
    if ( not defined $count ) {
        Carp::croak('Results not available for this Test::Weaken object');
    }
    return $count;
}

sub Test::Weaken::check_ignore {
    my ( $ignore, $max_errors, $compare_depth, $reporting_depth ) = @_;

    my $error_count = 0;

    $max_errors = 1 if not defined $max_errors;
    if ( not Scalar::Util::looks_like_number($max_errors) ) {
        Carp::croak('Test::Weaken::check_ignore max_errors must be a number');
    }
    $max_errors = 0 if $max_errors <= 0;

    $reporting_depth = -1 if not defined $reporting_depth;
    if ( not Scalar::Util::looks_like_number($reporting_depth) ) {
        Carp::croak(
            'Test::Weaken::check_ignore reporting_depth must be a number');
    }
    $reporting_depth = -1 if $reporting_depth < 0;

    $compare_depth = 0 if not defined $compare_depth;
    if ( not Scalar::Util::looks_like_number($compare_depth)
        or $compare_depth < 0 )
    {
        Carp::croak(
            'Test::Weaken::check_ignore compare_depth must be a non-negative number'
        );
    }

    return sub {
        my ($probe_ref) = @_;

        my $array_context = wantarray;

        my $before_weak =
            ( ref $probe_ref eq 'REF' and Scalar::Util::isweak( ${$probe_ref} ) );
        my $before_dump =
            Data::Dumper->new( [$probe_ref], [qw(proberef)] )
            ->Maxdepth($compare_depth)->Dump();
        my $before_reporting_dump;
        if ( $reporting_depth >= 0 ) {
            #<<< perltidy doesn't do this well
            $before_reporting_dump =
                Data::Dumper->new(
                    [$probe_ref],
                    [qw(proberef_before_callback)]
                )
                ->Maxdepth($reporting_depth)
                ->Dump();
            #>>>
        }

        my $scalar_return_value;
        my @array_return_value;
        if ($array_context) {
            @array_return_value = $ignore->($probe_ref);
        }
        else {
            $scalar_return_value = $ignore->($probe_ref);
        }

        my $after_weak =
            ( ref $probe_ref eq 'REF' and Scalar::Util::isweak( ${$probe_ref} ) );
        my $after_dump =
            Data::Dumper->new( [$probe_ref], [qw(proberef)] )
            ->Maxdepth($compare_depth)->Dump();
        my $after_reporting_dump;
        if ( $reporting_depth >= 0 ) {
            #<<< perltidy doesn't do this well
            $after_reporting_dump =
                Data::Dumper->new(
                    [$probe_ref],
                    [qw(proberef_after_callback)]
                )
                ->Maxdepth($reporting_depth)
                ->Dump();
            #<<<
        }

        my $problems       = q{};
        my $include_before = 0;
        my $include_after  = 0;

        if ( $before_weak != $after_weak ) {
            my $changed = $before_weak ? 'strengthened' : 'weakened';
            $problems .= "Probe referent $changed by ignore call\n";
            $include_before = defined $before_reporting_dump;
        }
        if ( $before_dump ne $after_dump ) {
            $problems .= "Probe referent changed by ignore call\n";
            $include_before = defined $before_reporting_dump;
            $include_after  = defined $after_reporting_dump;
        }

        if ($problems) {

            $error_count++;

            my $message .= q{};
            $message .= $before_reporting_dump
                if $include_before;
            $message .= $after_reporting_dump
                if $include_after;
            $message .= $problems;

            if ( $max_errors > 0 and $error_count >= $max_errors ) {
                $message
                    .= "Terminating ignore callbacks after finding $error_count error(s)";
                Carp::croak($message);
            }

            Carp::carp( $message . 'Above errors reported' );

        }

        return $array_context ? @array_return_value : $scalar_return_value;

    };
}

1;

__END__

=head1 NAME

Test::Weaken - Test that freed memory objects were, indeed, freed

=head1 SYNOPSIS

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/synopsis.t', 'synopsis')

=end Marpa::Test::Display:

    use Test::Weaken qw(leaks);
    use Data::Dumper;
    use Math::BigInt;
    use Math::BigFloat;
    use Carp;
    use English qw( -no_match_vars );

    my $good_test = sub {
        my $obj1 = Math::BigInt->new('42');
        my $obj2 = Math::BigFloat->new('7.11');
        [ $obj1, $obj2 ];
    };

    if ( !leaks($good_test) ) {
        print "No leaks in test 1\n"
            or Carp::croak("Cannot print to STDOUT: $ERRNO");
    }
    else {
        print "There were memory leaks from test 1!\n"
            or Carp::croak("Cannot print to STDOUT: $ERRNO");
    }

    my $bad_test = sub {
        my $array = [ 42, 711 ];
        push @{$array}, $array;
        $array;
    };

    my $bad_destructor = sub {'I am useless'};

    my $tester = Test::Weaken::leaks(
        {   constructor => $bad_test,
            destructor  => $bad_destructor,
        }
    );
    if ($tester) {
        my $unfreed_proberefs = $tester->unfreed_proberefs();
        my $unfreed_count     = @{$unfreed_proberefs};
        printf "Test 2: %d of %d original references were not freed\n",
            $tester->unfreed_count(), $tester->probe_count()
            or Carp::croak("Cannot print to STDOUT: $ERRNO");
        print "These are the probe references to the unfreed objects:\n"
            or Carp::croak("Cannot print to STDOUT: $ERRNO");
        for my $ix ( 0 .. $#{$unfreed_proberefs} ) {
            print Data::Dumper->Dump( [ $unfreed_proberefs->[$ix] ],
                ["unfreed_$ix"] )
                or Carp::croak("Cannot print to STDOUT: $ERRNO");
        }
    }

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

=head1 DESCRIPTION

A memory leak occurs when a Perl data structure is destroyed
but some of the contents of that structure
are not freed.
Leaked memory is a useless overhead.
Leaks can significantly impact system performance.
They can also cause an application to abend due to lack of memory.

In Perl,
circular references
are
a common cause of memory leaks.
Circular references are allowed in Perl,
but data structures containing circular references will leak memory
unless the programmer takes specific measures to prevent leaks.
Preventive measures include
weakening the references
and arranging to break the reference cycle just before
the structure is destroyed.

When using circular references,
it is easy to misdesign or misimplement a scheme for
preventing memory leaks.
Mistakes of this kind
have been hard to detect
in a test suite.

L<Test::Weaken|/"NAME"> allows easy detection of unfreed Perl data.
L<Test::Weaken|/"NAME"> allows you to examine the unfreed data,
even data that would usually have been made inaccessible.

L<Test::Weaken|/"NAME"> frees the test structure, then looks to see if any of the
contents of the structure were not actually deallocated.  By default,
L<Test::Weaken|/"NAME"> determines the contents of a data structure
by examining arrays and hashes, by following references, and by following
tied variables to their underlying object.
L<Test::Weaken|/"NAME"> does this recursively to
unlimited depth.

L<Test::Weaken|/"NAME"> can deal with circular references without going
into infinite loops.
L<Test::Weaken|/"NAME"> will not visit the same Perl data object twice.

=head2 Data Objects, Blessed Objects and Structures

B<Object> is a heavily overloaded term in the Perl world.
This document will use the term B<Perl data object>
or B<data object> to refer to any referenceable Perl datum,
including
scalars, arrays, hashes, references themselves, and code objects.
The full list of types of referenceable Perl data objects
is given in
L<the description of the ref builtin in the Perl documentation|perlfunc/"ref">.
An B<object> that has been blessed using the Perl
L<bless builtin|perlfunc/"bless">, will be called a B<blessed object>.

In this document,
a Perl B<data structure> (often just called a B<structure>)
is any group of Perl objects that are
B<co-mortal> -- expected to be destroyed at the same time.
Since the question is one of I<expected> lifetime,
whether an object is part of a data structure
is, in the last analysis, subjective.
Perl data structures can be any set of
Perl data objects.

=head2 The Contents of a Data Structure

A B<data structure> must have one object
that is designated as its B<top object>.
In most data structures, it is obvious which
data object should be designated as the top object.
The objects
in the data structure, including the top object,
are the B<contents> of that data structure.

L<Test::Weaken|/"NAME"> gets its B<test data structure>,
or B<test structure>,
from a closure.
The closure should return
a reference to the test structure.
This reference is called the B<test structure reference>.

=head2 Children and Descendants

The elements of an array are B<children> of the array.
The values of a hash are B<children> of the hash.
A referent is a B<child> of its reference.
The underlying object of a tied variable is a B<child> of the
tied variable.

The B<descendants> of a Perl data object are itself,
its children, and any children of one of its descendants.
By default, L<Test::Weaken|/"NAME"> determines the contents of a data structure
by recursing through the
descendants
of the top object of the test data structure.

If one data object is the descendant of a second object,
then the second data object is an B<ancestor> of the first object.
A data object is considered to be a descendant of itself,
and also to be one of its own ancestors.

L<Test::Weaken|/"NAME">'s default assumption,
that the contents of a data structure are the same as
its descendants, works
for many cases,
but not for all.
Ways to deal with
descendants that are not contents,
such as globals,
are dealt with in L<the section on persistent objects|/"Persistent Objects">.
Ways to deal with
contents that are not descendants,
such as inside-out objects,
are dealt with in
L<the section on nieces|/"Nieces">.

=head2 Builtin Types

This document will refer to the builtin type of objects.
Perl's B<builtin types> are the types Perl originally gives objects,
as opposed to B<blessed types>, the types assigned objects by
the L<bless function|perlfunc/"bless">.
The builtin types are listed in
L<the description of the ref builtin in the Perl documentation|perlfunc/"ref">.

Perl's L<ref function|perlfunc/"ref"> returns the blessed type of its
argument, if the argument has been blessed into a package.
Otherwise the 
L<ref function|perlfunc/"ref"> returns the builtin type.
The L<Scalar::Util/reftype function> always returns the builtin type,
even for blessed objects.

=head2 Persistent Objects

As a practical matter, a descendant that is not
part of the contents of a
test structure is only a problem
if its lifetime extends beyond that of the test
structure.
A descendant that is expected to stay around after
the test structure is destroyed
is called a B<persistent object>.

A persistent object is not a memory leak.
That's the problem.
L<Test::Weaken|/"NAME"> is trying to find memory leaks
and it looks for data objects that remain
after the test structure is freed.
But a persistent object is not expected to
disappear when the test structure goes away.

We need to
separate the unfreed data objects which are memory leaks,
from those which are persistent data objects.
It's usually easiest to do this after the test by
examining the return value of L</"unfreed_proberefs">.
The L</ignore> named argument can also be used
to pass L<Test::Weaken|/"NAME"> a closure
that separates out persistent data objects "on the fly".
These methods are described in detail
L<below|/"ADVANCED TECHNIQUES">.

=head2 Nieces

A B<niece data object> (also a B<niece object> or just a B<niece>)
is a data object that is part of the contents of a data 
structure,
but that is not a descendant of the top object of that
data structure.
When the OO technique called
"inside-out objects" is used,
most of the attributes of the blessed object will be
nieces.

In L<Test::Weaken|/"NAME">,
usually the easiest way to deal with non-descendant contents
is to make the
data structure you are trying to test
the B<lab rat> in a B<wrapper structure>.
In this scheme,
your test structure constructor will return a reference
to the top object of the wrapper structure,
instead of to the top object of the lab rat.

The top object of the wrapper structure will be a B<wrapper array>.
The wrapper array will contain the top object of the lab rat,
along with other objects.
The other objects need to be
chosen so that the contents of the 
wrapper array are exactly
the wrapper array itself, plus the contents
of the lab rat.

It is not always easy to find the right objects to put into the wrapper array.
In particular, determining the contents of the lab rat may
require what
amounts to a recursive scan of the descendants of the lab rat's
top object.

As an alternative to using a wrapper,
it is possible to have L<Test::Weaken|/"NAME"> add
contents "on the fly," while it is scanning the lab rat.
This can be done using L<the C<contents> named argument|/contents>,
which takes a closure as its value.

=head2 Why the Test Structure is Passed via a Closure

L<Test::Weaken|/"NAME"> gets its test structure reference
indirectly,
as the return value from a
B<test structure constructor>.
Why so roundabout?

Because the indirect way is the easiest.
When you
create the test structure
in L<Test::Weaken|/"NAME">'s calling environment,
it takes a lot of craft to avoid
leaving
unintended references to the test structure in that calling environment.
It is easy to get this wrong.
Those unintended references will
create memory leaks that are artifacts of the test environment.
Leaks that are artifacts of the test environment
are very difficult to sort out from the real thing.

The B<closure-local strategy> is the easiest way
to avoid leaving unintended references to the
contents of Perl data objects.
Using the closure-local strategy means working
entirely within a closure,
using only data objects local to that closure.
Data objects local to a closure will be destroyed when the
closure returns, and any references they held will be released.
The closure-local strategy makes
it relatively easy to be sure that nothing is left behind
that will hold an unintended reference
to any of the contents
of the test structure.

Nothing prevents a user from
subverting the closure-local strategy.
A test structure constructor
can return a reference to a test structure
created from Perl data objects in any scope the user desires.

=head2 Returns and Exceptions

The methods of L<Test::Weaken|/"NAME"> do not return errors.
Errors are always thrown as exceptions.

=head1 PORCELAIN METHODS

=head2 leaks

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/snippet.t', 'leaks snippet')

=end Marpa::Test::Display:

    use Test::Weaken;
    use English qw( -no_match_vars );

    my $tester = Test::Weaken::leaks(
        {   constructor => sub { Buggy_Object->new() },
            destructor  => \&destroy_buggy_object,
        }
    );
    if ($tester) {
        print "There are leaks\n" or Carp::croak("Cannot print to STDOUT: $ERRNO");
    }

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

Returns a
Perl false if no unfreed data objects were detected.
If unfreed data objects were detected,
returns an evaluated L<Test::Weaken|/"NAME"> class instance.

Instances of the L<Test::Weaken|/"NAME"> class are called B<testers>.
An B<evaluated> tester is one on which the
tests have been run,
and for which results are available.

Users who only want to know if there were unfreed data objects can
test the return value of L</"leaks"> for Perl true or false.
Arguments to the L</"leaks"> static method are passed as a reference to
a hash of named arguments.
L</leaks> can also be called in a special "short form",
where the test structure constructor and test structure destructor
are passed directly as code references.

=over 4

=item constructor

The B<constructor> argument is required.
Its value must be a code reference to
the B<test structure constructor>.
The test structure constructor
should return a reference to the test structure.
It is best to follow strictly the closure-local strategy,
as described above.

When L</"leaks"> is called using the "short form",
the code reference to the test structure constructor
must be the first argument to L</"leaks">.

=item destructor

The B<destructor> argument is optional.
If specified, its value must be a code reference
to the B<test structure destructor>.

Some test structures require
a destructor to be called when
they are freed.
The primary purpose for
the test structure destructor is to enable
L<Test::Weaken|/"NAME"> to work with these data structures.
The test structure destructor is called
just before L<Test::Weaken|/"NAME"> tries
to free the test structure
by setting the test structure reference to C<undef>.
The test structure destructor will be passed one argument,
the test structure reference.
The return value of the test structure destructor is ignored.

When L</"leaks"> is called using the "short form",
a code reference to the test structure destructor is the optional, second argument to L</"leaks">.

=item ignore

=begin Marpa::Test::Display:

## start display
## next 2 displays
is_file($_, 't/ignore.t', 'ignore snippet')

=end Marpa::Test::Display:

    sub ignore_my_global {
        my ($probe) = @_;
        return ( Scalar::Util::blessed($probe) && $probe->isa('MyGlobal') );
    }

    my $tester = Test::Weaken::leaks(
        {   constructor => sub { MyObject->new() },
            ignore      => \&ignore_my_global,
        }
);

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

The B<ignore> argument is optional.
It can be used to make a decision,
specific to each Perl data object,
on whether that object is
ignored, or tracked and examined for children.

Use of the L</ignore> argument should be avoided.
Filtering the probe references that are
returned by
L</"unfreed_proberefs">
is easier, safer and
faster.
But
filtering after the fact
is not always practical.
For example, if large or complicated sub-objects
need to be filtered out,
it may be easiest to do so
before they end up in the results.

When specified, the value of the L</ignore> argument must be a
reference to a callback subroutine.
If the reference to the callback subroutine
is C<$ignore>, L<Test::Weaken|/"NAME">'s call to it will be the equivalent
of C<< $ignore->($safe_copy) >>,
where C<$safe_copy> is a copy of 
a probe reference to a Perl data object.

The L</ignore> callback will be made once
for every Perl data object when it is about
to be tracked,
and once for every data object when it is about to be
examined for children.
The callback subroutine should return a Perl true value if the probe reference is
to a data object which should be ignored.
If the data object should be tracked and examined for children,
the callback subroutine should return a Perl false.

For safety, L<Test::Weaken|/"NAME"> passes
the L</ignore> callback a copy of the internal
probe reference.
This prevents the user
altering
the probe reference itself.
However,
the data object referred to by the probe reference is not copied.
Everything that is referred to, directly or indirectly,
by this
probe reference
should be left unchanged by the L</ignore>
callback.
The result of modifying the probe referents might be
an exception, an abend, an infinite loop, or erroneous results.

The example above shows a common use of the L</ignore>
callback.
In this a blessed object is ignored, I<but not>
the references to it.
This is typically what is wanted.
Often you know certain
objects are outside the contents of your test structure,
but you have references to those objects that I<are> part of
the contents of your test structure.
In that case, you want to know if the references are leaking,
but you do not want to see reports 
when the outside objects themselves are persistent.
Compare this with the example for the L</contents> callback below.

L</ignore> callbacks are best kept simple.
Defer as much of the analysis as you can
until after the test is completed.
L</ignore> callbacks 
can be a significant overhead.

L<Test::Weaken|/"NAME"> offers some help in debugging
L</ignore> callback subroutines.
See L<below|/"Debugging Ignore Subroutines">.

=item contents

=begin Marpa::Test::Display:

## start display
## next 2 displays
is_file($_, 't/contents.t', 'contents sub snippet')

=end Marpa::Test::Display:

    sub contents {
        my ($probe) = @_;
        return unless Scalar::Util::reftype $probe eq 'REF';
        my $thing = ${$probe};
        return unless Scalar::Util::blessed($thing);
        return unless $thing->isa('MyObject');
        return ( $thing->data, $thing->moredata );
    } ## end sub MyObject::contents

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

=begin Marpa::Test::Display:

## start display
## next 2 displays
is_file($_, 't/contents.t', 'contents named arg snippet')

=end Marpa::Test::Display:

    my $tester = Test::Weaken::leaks(
        {   constructor => sub { return MyObject->new },
            contents    => \&MyObject::contents
        }
    );

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

The B<contents> argument is optional.
It can be used to tell L<Test::Weaken|/"NAME"> about additional
Perl data objects that need to be included,
along with their children,
in order to find all of the contents of the test data structure.

Use of the L</contents> argument should be avoided
when possible.
Instead of using the L</contents> argument, it is
often possible to have the constructor
create a reference to a "wrapper structure",
L<as described above in the section on nieces|/"Nieces">.
The L</contents> argument is
for situations where the "wrapper structure"
technique is not practical.
If, for example,
creating the wrapper structure would involve a recursive
descent through the lab rat object,
using the L</contents> argument may be easiest.

When specified, the value of the L</contents> argument must be a
reference to a callback subroutine.
If the reference is C<$contents>,
L<Test::Weaken|/"NAME">'s call to it will be the equivalent
of C<< $contents->($safe_copy) >>,
where C<$safe_copy> is a copy of the probe reference to
a Perl data object.
The L</contents> callback is made once
for every Perl data object
when that Perl data object is
about to be examined for children.
This can impose a significant overhead.

The example of a L</contents> callback above adds data objects whenever it
encounters a I<reference> to a blessed object.
Compare this with the example for the L</ignore> callback above.
Checking for references to blessed objects will not produce the same
behavior as checking for the blessed objects themselves --
there may be many references to a single
object.

The callback subroutine will be evaluated in array context.
It should return a list of additional Perl data objects
to be tracked and examined for children.
This list may be empty.

The L</contents> and L</ignore> callbacks can be used together.
If, for an argument Perl data object, the L</ignore> callback returns
true, the objects returned by the L</contents> callback
will be used B<instead> of the children for the argument data object.
If, for an argument Perl data object, the L</ignore> callback returns
false, the objects returned by the L</contents> callback
will be used B<in addition> to the children for the argument data object.
Together,
the L</contents> and L</ignore> callbacks can be used
to completely customize the way in which
L<Test::Weaken|/"NAME">
determines the contents of a data structure.

For safety, L<Test::Weaken|/"NAME"> passes
the L</contents> callback a copy of the internal
probe reference.
This prevents the user
altering
the probe reference itself.
However,
the data object referred to by the probe reference is not copied.
Everything that is referred to, directly or indirectly,
by this
probe reference
should be left unchanged by the L</contents>
callback.
The result of modifying the probe referents might be
an exception, an abend, an infinite loop, or erroneous results.

=item tracked_types

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/filehandle.t', 'tracked_types snippet')

=end Marpa::Test::Display:

    my $test = Test::Weaken::leaks(
        {   constructor => sub {
                my $obj = MyObject->new;
                return $obj;
            },
            tracked_types => ['GLOB'],
        }
    );

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

The B<tracked_types> argument is optional.
If specified, the value of the
B<tracked_types> argument must be a reference to an array
of the names of additional builtin types to track.

Objects of builtin types ARRAY, HASH, REF,
SCALAR, VSTRING, and CODE are tracked
by default.
The builtin types that are not tracked,
and which you may wish to add,
are GLOB, IO, FORMAT and LVALUE.
They are not tracked by default because,
for L<reasons given below|/"Tracked Objects">,
tracking them usually causes more trouble than it saves.

=back

=head2 unfreed_proberefs

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/snippet.t', 'unfreed_proberefs snippet')

=end Marpa::Test::Display:

    use Test::Weaken;
    use English qw( -no_match_vars );

    my $tester = Test::Weaken::leaks( sub { Buggy_Object->new() } );
    if ($tester) {
        my $unfreed_proberefs = $tester->unfreed_proberefs();
        my $unfreed_count     = @{$unfreed_proberefs};
        printf "%d of %d references were not freed\n",
            $tester->unfreed_count(), $tester->probe_count()
            or Carp::croak("Cannot print to STDOUT: $ERRNO");
        print "These are the probe references to the unfreed objects:\n"
            or Carp::croak("Cannot print to STDOUT: $ERRNO");
        for my $ix ( 0 .. $#{$unfreed_proberefs} ) {
            print Data::Dumper->Dump( [ $unfreed_proberefs->[$ix] ],
                ["unfreed_$ix"] )
                or Carp::croak("Cannot print to STDOUT: $ERRNO");
        }
    }

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

Returns a reference to an array of probe references to the unfreed data objects.
Throws an exception if there is a problem,
for example if the tester has not yet been evaluated.

The return value can be examined
to pinpoint the source of a leak.
A user may also analyze the return value
to produce her own statistics about unfreed data objects.

=head2 unfreed_count

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/snippet.t', 'unfreed_count snippet')

=end Marpa::Test::Display:

    use Test::Weaken;
    use English qw( -no_match_vars );

    my $tester = Test::Weaken::leaks( sub { Buggy_Object->new() } );
    next TEST if not $tester;
    printf "%d objects were not freed\n", $tester->unfreed_count(),
        or Carp::croak("Cannot print to STDOUT: $ERRNO");

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

Returns the count of unfreed data objects.
This count will be exactly the length of the array referred to by
the return value of the L</"unfreed_proberefs"> method.
Throws an exception if there is a problem,
for example if the tester has not yet been evaluated.

=head2 probe_count

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/snippet.t', 'probe_count snippet')

=end Marpa::Test::Display:

        use Test::Weaken;
        use English qw( -no_match_vars );

        my $tester = Test::Weaken::leaks(
            {   constructor => sub { Buggy_Object->new() },
                destructor  => \&destroy_buggy_object,
            }
        );
        next TEST if not $tester;
        printf "%d of %d objects were not freed\n",
            $tester->unfreed_count(), $tester->probe_count()
            or Carp::croak("Cannot print to STDOUT: $ERRNO");

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

Returns the total number of probe references in the test,
including references to freed data objects.
This is the count of probe references
after L<Test::Weaken|/"NAME"> was finished finding the descendants of
the test structure reference,
but before L<Test::Weaken|/"NAME"> called the test structure destructor or reset the
test structure reference to C<undef>.
Throws an exception if there is a problem,
for example if the tester has not yet been evaluated.

=head1 PLUMBING METHODS

Most users can skip this section.
The plumbing methods exist to satisfy object-oriented purists,
and to accommodate the rare user who wants to access the probe counts
even when the test did find any unfreed data objects.

=head2 new

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/snippet.t', 'new snippet')

=end Marpa::Test::Display:

    use Test::Weaken;
    use English qw( -no_match_vars );

    my $tester        = Test::Weaken->new( sub { My_Object->new() } );
    my $unfreed_count = $tester->test();
    my $proberefs     = $tester->unfreed_proberefs();
    printf "%d of %d objects freed\n",
        $unfreed_count,
        $tester->probe_count()
        or Carp::croak("Cannot print to STDOUT: $ERRNO");

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

The L</"new"> method takes the same arguments as the L</"leaks"> method, described above.
Unlike the L</"leaks"> method, it always returns an B<unevaluated> tester.
An B<unevaluated> tester is one on which the test has not yet
been run and for which results are not yet available.
If there are any problems, the L</"new">
method throws an exception.

The L</"test"> method is the only method that can be called successfully on
an unevaluated tester.
Calling any other method on an unevaluated tester causes an exception to be thrown.

=head2 test

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/snippet.t', 'test snippet')

=end Marpa::Test::Display:

    use Test::Weaken;
    use English qw( -no_match_vars );

    my $tester = Test::Weaken->new(
        {   constructor => sub { My_Object->new() },
            destructor  => \&destroy_my_object,
        }
    );
    printf "There are %s\n", ( $tester->test() ? 'leaks' : 'no leaks' )
        or Carp::croak("Cannot print to STDOUT: $ERRNO");

Converts an unevaluated tester into an evaluated tester.
It does this by performing the test
specified
by the arguments to the L</"new"> constructor
and recording the results.
Throws an exception if there is a problem,
for example if the tester had already been evaluated.

The L</"test"> method returns the count of unfreed data objects.
This will be identical to the length of the array
returned by L</"unfreed_proberefs"> and
the count returned by L</"unfreed_count">.

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

=head1 ADVANCED TECHNIQUES

=head2 Tracing Leaks

=head3 Avoidance

L<Test::Weaken|/"NAME"> makes tracing leaks easier, but avoidance is
still by far the best way,
and L<Test::Weaken|/"NAME"> helps with that.
You need to use test-driven development, L<Test::More>,
modular tests in a C<t/> subdirectory,
and revision control.
These are all very good ideas for many other reasons.

Make L<Test::Weaken|/"NAME"> part of your test suite.
Test frequently, so that when a leak occurs,
you'll have a good idea of what changes were made since
the last successful test.
Often, examining these changes is enough to
tell where the leak was introduced.

=head3 Adding Tags

The L</"unfreed_proberefs"> method returns an array containing
probes to
the unfreed
data objects.
This can be used
to find the source of leaks.
If circumstances allow it,
you might find it useful to add "tag" elements to arrays and hashes
to aid in identifying the source of a leak.

=head3 Using Referent Addresses

You can quasi-uniquely identify data objects using
the referent addresses of the probe references.
A referent address
can be determined by using 
L<Scalar::Util/refaddr>.
You can also obtain the referent address of a reference by adding 0
to the reference.

Note that in other Perl documentation, the term "reference address" is often
used when a referent address is meant.
Any given reference has both a reference address and a referent address.
The B<reference address> is the reference's own location in memory.
The B<referent address> is the address of the Perl data object to which the reference refers.
It is the referent address that interests us here and,
happily, it is
the referent address that both zero addition
and L<refaddr|Scalar::Util/refaddr> return.

=head3 Other Techniques

Sometimes, when you are interested in why an object is not being freed,
you want to seek out the reference
that keeps the object's refcount above 0.
L<Devel::FindRef> can be useful for this.

=head2 More about Quasi-unique Addresses

I call referent addresses "quasi-unique", because they are only
unique at a
specific point in time.
Once an object is freed, its address can be reused.
Absent other evidence,
a data object with a given referent address
is not 100% certain to be
the same data object
as the object that had the same address earlier.
This can bite you
if you're not careful.

To be sure an earlier data object and a later object with the same address
are actually the same object,
you need to know that the earlier object will be persistent,
or to compare the two objects.
If you want to be really pedantic,
even an exact match from a comparison doesn't settle the issue.
It is possible that two indiscernable
(that is, completely identical)
objects with the same referent address are different in the following
sense:
the first data object might have been destroyed
and a second, identical,
object created at the same address.
But for most practical programming purposes,
two indiscernable data objects can be regarded as the same object.

=head2 Debugging Ignore Subroutines

=head3 check_ignore

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/ignore.t', 'check_ignore 1 arg snippet')

=end Marpa::Test::Display:

    $tester = Test::Weaken::leaks(
        {   constructor => sub { MyObject->new() },
            ignore => Test::Weaken::check_ignore( \&ignore_my_global ),
        }
    );

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

=begin Marpa::Test::Display:

## start display
## next display
is_file($_, 't/ignore.t', 'check_ignore 4 arg snippet')

=end Marpa::Test::Display:

    $tester = Test::Weaken::leaks(
        {   constructor => sub { DeepObject->new() },
            ignore      => Test::Weaken::check_ignore(
                \&cause_deep_problem, 99, 0, $reporting_depth
            ),
        }
    );

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

It can be hard to determine if
L</ignore> callback subroutines
are inadvertently
modifying the test structure.
The
L<Test::Weaken::check_ignore|/"check_ignore">
static method is
provided to make this task easier.
L<Test::Weaken::check_ignore|/"check_ignore">
constructs
a debugging wrapper from
four arguments, three of which are optional.
The first argument must be the ignore callback
that you are trying to debug.
This callback is called the test subject, or
B<lab rat>.

The second, optional argument, is the maximum error count.
Below this count, errors are reported as warnings using L<Carp::carp|Carp>.
When the maximum error count is reached, an
exception is thrown using L<Carp::croak|Carp>.
The maximum error count, if defined,
must be an number greater than or equal to 0.
By default the maximum error count is 1,
which means that the first error will be thrown
as an exception.

If the maximum error count is 0, all errors will be reported
as warnings and no exception will ever be thrown.
Infinite loops are a common behavior of
buggy lab rats,
and setting the maximum error
count to 0 will usually not be something you
want to do.

The third, optional, argument is the B<compare depth>.
It is the depth to which the probe referents will be checked,
as described below.
It must be a number greater than or equal to 0.
If the compare depth is 0, the probe referent is checked
to unlimited depth.
By default the compare depth is 0.

This fourth, optional, argument is the B<reporting depth>.
It is the depth to which the probe referents are dumped
in
L<check_ignore's|/"check_ignore">
error messages.
It must be a number greater than or equal to -1.
If the reporting depth is 0, the object is dumped to unlimited depth.
If the reporting depth is -1, there is no dump in the error message.
By default, the reporting depth is -1.

L<Test::Weaken::check_ignore|/"check_ignore">
returns a reference to the wrapper callback.
If no problems are detected,
the wrapper callback behaves exactly like the lab rat callback,
except that the wrapper is slower.

To discover when and if the lab rat callback is
altering its arguments,
L<Test::Weaken::check_ignore|/"check_ignore">
compares the test structure
before the lab rat is called,
to the test structure after the lab rat returns.
L<Test::Weaken::check_ignore|/"check_ignore">
compares the before and after test structures in two ways.
First, it dumps the contents of each test structure using
L<Data::Dumper>.
For comparison purposes,
the dump using L<Data::Dumper> is performed with C<Maxdepth>
set to the compare depth as described above.
Second, if the immediate probe referent has builtin type REF,
L<Test::Weaken::check_ignore|/"check_ignore">
determines whether the immediate probe referent
is a weak reference or a strong one.

If either comparison shows a difference,
the wrapper treats it as a problem, and
produces an error message.
This error message is either a L<Carp::carp|Carp> warning or a
L<Carp::croak|Carp> exception, depending on the number of error
messages already reported and the setting of the
maximum error count.
If the reporting depth is a non-negative number, the error
message includes a dump from L<Data::Dumper> of the
test structure.
L<Data::Dumper's|Data::Dumper> C<Maxdepth>
for reporting purposes is the reporting depth as described above.

A user who wants other features, such as deep checking
of the test structure
for strengthened references,
can easily 
copy
L<Test::Weaken::check_ignore|/"check_ignore">
from the L<Test::Weaken|/"NAME"> source
and hack it up.
L<check_ignore|/"check_ignore">
is a static method
that does not use any L<Test::Weaken|/"NAME">
package resources.
The hacked version can reside anywhere,
and does not need to
be part of the L<Test::Weaken|/"NAME"> package.

=head1 EXPORTS

By default, L<Test::Weaken|/"NAME"> exports nothing.
Optionally, L</"leaks"> may be exported.

=head1 IMPLEMENTATION DETAILS

=head2 Overview

L<Test::Weaken|/"NAME"> first recurses through the test structure.
Starting from the test structure reference,
it examines data objects for children recursively,
until it has found the complete contents of the test structure.
The test structure is explored to unlimited depth.
For each tracked Perl data object, a
probe reference is created.
Tracked data objects are recorded.
In the recursion, no object is visited twice,
and infinite loops will not occur,
even in the presence of cycles.

Once recursion through the test structure is complete,
the probe references are weakened.
This prevents the probe references from interfering
with the normal deallocation of memory.
Next, the test structure destructor is called,
if there is one.

Finally, the test structure reference is set to C<undef>.
This should trigger the deallocation of the entire contents of the test structure.
To check that this happened, L<Test::Weaken|/"NAME"> dereferences the probe references.
If the referent of a probe reference was deallocated,
the value of that probe reference will be C<undef>.
If a probe reference is still defined at this point,
it refers to an unfreed Perl data object.

=head2 Tracked Objects

By default,
objects of builtin types ARRAY, HASH, REF,
SCALAR, VSTRING, and CODE are tracked.
By default,
GLOB, IO, FORMAT and LVALUE objects are not tracked.

L<Data::Dumper> does not deal with
IO and LVALUE objects
gracefully,
issuing a cryptic warning whenever it encounters them.
Since L<Data::Dumper> is a Perl core module
in extremely wide use, this suggests that these IO and LVALUE
objects are, to put it mildly,
not commonly encountered as the contents of data structures.

GLOB objects
usually either refer
to an entry in the Perl symbol table,
or are associated with a filehandle.
Either way, the assumption they will share
the lifetime of their parent data object
is thrown into doubt.
The trouble saved by ignoring GLOB objects seems 
to outweigh any advantage that would come from tracking
them.
IO objects, which are ignored because of L<Data::Dumper> issues,
are often associated with GLOB objects.

FORMAT objects are always global, and therefore
can be expected to be persistent.
Use of FORMAT objects is officially deprecated.
L<Data::Dumper> does not deal with
FORMAT objects gracefully,
issuing a cryptic warning whenever it encounters one.

This version of L<Test::Weaken|/"NAME"> might someday be run
in a future version of Perl
and encounter builtin types it does not know about.
By default, those new builtin types will not be tracked.
Any builtin type may be added to the list of builtin types to be
tracked with the
L<tracked_types named argument|/"tracked_types">.

=head2 Examining Objects for Children

Objects of builtin type
ARRAY, HASH, REF,
SCALAR, VSTRING, GLOB, and LVALUE
are examined for children.
Specifically,
elements of ARRAY objects,
values of HASH objects,
and referents of REF objects
are children.
Underlying tied variables are also children.

Objects of type CODE are
not examined for children.
Not examining CODE objects for children
can be seen as a limitation, because
closures do hold internal references to data objects.
Future versions of L<Test::Weaken|/"NAME"> may examine CODE objects.

The default method of recursing through a test structure
to find its contents can be customized.
The L</ignore> callback can be used to force an object
not to be examined for children.
The L</contents> callback can be used to add user-determined
contents to the test structure.

=head1 AUTHOR

Jeffrey Kegler

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-weaken at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Weaken>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

=begin Marpa::Test::Display:

## skip display

=end Marpa::Test::Display:

    perldoc Test::Weaken

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Weaken>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Weaken>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Weaken>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Weaken>

=back

=head1 SEE ALSO

Potential users will want to compare L<Test::Memory::Cycle> and
L<Devel::Cycle>, which examine
existing data structures non-destructively.
L<Devel::Leak> also covers similar ground, although it requires
Perl to be compiled with C<-DDEBUGGING> in order to work.  L<Devel::Cycle>
looks inside closures if PadWalker is present, a feature L<Test::Weaken|/"NAME">
does not have at present.

=head1 ACKNOWLEDGEMENTS

Thanks to jettero, Juerd, morgon and perrin of Perlmonks for their advice.
Thanks to Lincoln Stein (developer of L<Devel::Cycle>) for
test cases and other ideas.
Kevin Ryde made many important suggestions
and provided the test cases which
provided the impetus
for the versions 2.000000 and after.
For version 3.000000, Kevin also provided patches.

=head1 LICENSE AND COPYRIGHT

Copyright 2007-2009 Jeffrey Kegler, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.10.

=cut

1;    # End of Test::Weaken

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
