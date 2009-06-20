package Test::Weaken;

use strict;
use warnings;

require Exporter;

use base qw(Exporter);
our @EXPORT_OK = qw(leaks poof);
our $VERSION   = '2.003_004';

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
use Scalar::Util qw(refaddr reftype isweak weaken);

sub follow {
    my ( $self, $base_probe ) = @_;
    my $ignore          = $self->{ignore};
    my $contents        = $self->{contents};
    my $trace_maxdepth  = $self->{trace_maxdepth};
    my $trace_following = $self->{trace_following};
    my $trace_tracking  = $self->{trace_tracking};

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

    FOLLOW_OBJECT: while ( my $follow_probe = pop @follow_probes ) {

        # The follow probes are to objects which either will not be
        # tracked or which have already been added to @tracking_probes

        next FOLLOW_OBJECT if $already_followed{ $follow_probe + 0 }++;

        my $object_type = reftype $follow_probe;

        if ( defined $ignore ) {
            my $safe_copy = $follow_probe;
            next FOLLOW_OBJECT if $ignore->($safe_copy);
        }

        if ($trace_following) {
            ## no critic (ValuesAndExpressions::ProhibitLongChainsOfMethodCalls)
            print {*STDERR} 'Following: ',
                Data::Dumper->new( [$follow_probe], [qw(tracking)] )->Terse(1)
                ->Maxdepth($trace_maxdepth)->Dump
                or Carp::croak("Cannot print to STDOUT: $ERRNO");
            ## use critic
        }

        my @child_probes = ();

        FIND_CHILDREN: {
            if ( $object_type eq 'ARRAY' ) {
                foreach my $i ( 0 .. $#{$follow_probe} ) {
                    if ( exists $follow_probe->[$i] ) {
                        push @child_probes, \( $follow_probe->[$i] );
                    }
                }
                if ( defined $contents ) {
                    my $safe_copy = $follow_probe;
                    push @child_probes,
                        map { \$_ } ( $contents->($safe_copy) );
                }
                last FIND_CHILDREN;
            } ## end if ( $object_type eq 'ARRAY' )

            if ( $object_type eq 'HASH' ) {
                @child_probes = map { \$_ } values %{$follow_probe};
                if ( defined $contents ) {
                    my $safe_copy = $follow_probe;
                    push @child_probes,
                        map { \$_ } ( $contents->($safe_copy) );
                }
                last FIND_CHILDREN;
            }

            if ( $object_type eq 'REF' ) {
                @child_probes = ( ${$follow_probe} );
                if ( defined $contents ) {
                    my $safe_copy = $follow_probe;
                    push @child_probes,
                        map { \$_ } ( $contents->($safe_copy) );
                }
                last FIND_CHILDREN;
            } ## end if ( $object_type eq 'REF' )

        } ## end FIND_CHILDREN:

        next FOLLOW_OBJECT if not scalar @child_probes;

        CHILD_PROBE: for my $child_probe (@child_probes) {

            my $child_type = Scalar::Util::reftype $child_probe;

            my $new_tracking_probe;
            my $new_follow_probe;

            DECIDE_TRACK_OR_FOLLOW: {

                if ( $child_type eq 'REF' ) {
                    $new_follow_probe = $new_tracking_probe =
                        \${$child_probe};
                    last DECIDE_TRACK_OR_FOLLOW;
                }

                if (   $child_type eq 'SCALAR'
                    or $child_type eq 'VSTRING' )
                {
                    $new_tracking_probe = \${$child_probe};
                    last DECIDE_TRACK_OR_FOLLOW;
                }

                if ( $child_type eq 'HASH' ) {
                    $new_follow_probe = $new_tracking_probe =
                        \%{$child_probe};
                    last DECIDE_TRACK_OR_FOLLOW;
                }

                if ( $child_type eq 'ARRAY' ) {
                    $new_follow_probe = $new_tracking_probe =
                        \@{$child_probe};
                    last DECIDE_TRACK_OR_FOLLOW;
                }

                if ( $child_type eq 'CODE' ) {
                    $new_tracking_probe = \&{$child_probe};
                    last DECIDE_TRACK_OR_FOLLOW;
                }

                # FORMAT, LVALUE, GLOB, IO are not tracked or followed

            } ## end DECIDE_TRACK_OR_FOLLOW:

            push @follow_probes, $new_follow_probe
                if defined $new_follow_probe;

            next CHILD_PROBE unless defined $new_tracking_probe;

            next CHILD_PROBE if $already_tracked{ $new_tracking_probe + 0 }++;

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
        grep { ref $_ eq 'REF' and isweak ${$_} } @{$probes};
    $self->{strong_probe_count} =
        $self->{probe_count} - $self->{weak_probe_count};

    if ( not $test ) {
        $self->{unfreed_probes} = $probes;
        return scalar @{$probes};
    }

    for my $probe ( @{$probes} ) {
        weaken($probe);
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
        if ( ref $probe eq 'REF' and isweak ${$probe} ) {
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

        my $before_weak =
            ( ref $probe_ref eq 'REF' and isweak( ${$probe_ref} ) );
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

        my $return_value = $ignore->($probe_ref);

        my $after_weak =
            ( ref $probe_ref eq 'REF' and isweak( ${$probe_ref} ) );
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

        return $return_value if not $problems;

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
        return $return_value;
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

C<Test::Weaken> allows easy detection of unfreed Perl data.
C<Test::Weaken> allows you to examine the unfreed data,
even data that would usually have been made inaccessible.

C<Test::Weaken> frees the test structure, then looks to see if any of the
contents of the structure were not actually deallocated.  By default,
C<Test::Weaken> determines the B<contents> of a data structure
by examining arrays and hashes and following references.
C<Test::Weaken> does this recursively to
unlimited depth.

C<Test::Weaken> can deal with circular references without going
into infinite loops.
C<Test::Weaken> will not visit the same Perl data object twice.

=head2 Data Objects, Blessed Objects and Structures

B<Object> is a heavily overloaded term in the Perl world.
This document will use the term B<Perl data object>
or B<data object> to refer to any referenceable Perl datum,
including
scalars, arrays, hashes, references themselves, and code objects.
The full list of types of referenceable Perl data objects
is given in the documentation of the Perl
C<ref> builtin in the L<perlfunc man page|perlfunc>.
An B<object> that has been blessed using the Perl
C<bless> builtin, will be called a B<blessed object>.

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

C<Test::Weaken> gets its B<test data structure>,
or B<test structure>,
from a closure.
The closure should return
a reference to the B<test structure>.
This reference is called the B<test structure reference>.

=head2 Followed Objects and Descendants

A Perl data object is called a B<followed object>
if C<Test::Weaken> examines it while it is looking for
the contents of the test data structure.
By default, C<Test::Weaken> determines the contents by recursing
through the
descendants of the top object of the test data structure.

The B<descendants> of a Perl data object are itself,
its children, and any children of one of its descendants.
The B<child> of a reference is its referent.
The B<children> of an array are
its elements.
The B<children> of a hash are its values.

If one data object is the descendant of a second object,
then the second data object is an B<ancestor> of the first object.
A data object is considered to be a descendant of itself,
and also to be one of its own ancestors.

C<Test::Weaken>'s default assumption,
that the contents of a data structure are the same as
its descendants, works
for many cases,
but not for all.
Ways to deal with
descendants that are not contents,
such as globals,
are dealt with in L<the section on persistent objects|"Persistent Objects">.
Ways to deal with
contents that are not descendants,
such as inside-out objects,
are deal with in
L<the section on nieces|"Nieces">.

=head2 Persistent Objects

As a practical matter, a descendant that is not
part of the contents of a
test structure is only a problem
if its lifetime extends beyond that of the test
structure.
A descendant that stays around after
the test structure is called a B<persistent object>.

A persistent object is not a memory leak.
That's the problem.
C<Test::Weaken> is trying to find memory leaks
and it looks for data objects that remain
after the test structure is freed.
But a persistent object is not expected to
disappear when the test structure goes away.

We need to
separate the unfreed data objects which are memory leaks,
from those which are persistent data objects.
It's usually easiest to do this after the test by
examining the return value of L</unfreed_proberefs>.
The L</ignore> named argument can also be used
to pass C<Test::Weaken> a closure
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

In C<Test::Weaken>,
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
lab rat and the descendants of the wrapper array
are identical.

To fill the wrapper array, you need to find ancestor objects
for any contents of the lab rat that are not descendants of
the lab rat top object.
Once you do this, the contents of the lab rat,
the contents of the wrapper structure,
and the descendants of the wrapper structure
will all be the same.

It is not always easy to find the right objects to put into the wrapper array.
In particular, determining the contents of the lab rat may
require what
amounts to a recursive scan of the descendants of the lab rat's
top object,
something C<Test::Weaken> already does.

As an alternative to using a wrapper,
it is possible to have C<Test::Weaken> add
contents "on the fly," while it is scanning the lab rat.
This can be done using L<the C<contents> named argument|"contents">,
which takes a closure as its value.

=head2 Why the Test Structure is Passed via a Closure

C<Test::Weaken> gets its test structure reference
indirectly,
as the return value from a
B<test structure constructor>.
Why so roundabout?

Because the indirect way is the easiest.
When you
create the test structure
in C<Test::Weaken>'s calling environment,
it takes a lot of craft to avoid
leaving
unintended references to the test structure in that calling environment.
It is easy to get this wrong.
In other words,
mistakes in setting up the test structure
create memory leaks that are artifacts of the test environment.
These artifacts are very difficult to sort out from the real thing.

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

To help the user to follow the closure-local strategy,
C<Test::Weaken> requires that its test structure reference
be the return value of a closure.
The closure-local strategy is safe.
It is almost always right thing to do.
C<Test::Weaken> makes it the easy thing to do.

Nothing prevents a user from
subverting the closure-local strategy.
A test structure constructor
can return a reference to a test structure
created from Perl data objects in any scope the user desires.

=head2 Returns and Exceptions

The methods of C<Test::Weaken> do not return errors.
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
returns an evaluated C<Test::Weaken> class instance.

Instances of the C<Test::Weaken> class are called B<testers>.
An B<evaluated> tester is one on which the
tests have been run,
and for which results are available.

Users who only want to know if there were unfreed data objects can
test the return value of C<leaks> for Perl true or false.
Arguments to the C<leaks> static method may be passed as a reference to
a hash of named arguments,
or directly as code references.

=over 4

=item constructor

The B<test structure constructor> is a required argument.
It must be a code reference.
When the arguments are passed directly as code references,
the test structure constructor must be the first argument to C<leaks>.
When named arguments are used,
the test structure constructor must be the value of the C<constructor> named argument.

The test structure constructor
should build the test structure
and return a reference to it.
It is best to follow strictly the closure-local strategy,
as described above.

=item destructor

The B<test structure destructor> is an optional argument.
If specified, it must be a code reference.
When the arguments are passed directly as code references,
the test structure destructor is the second, optional, argument to C<leaks>.
When named arguments are used,
the test structure destructor must be the value of the C<destructor> named argument.

If specified,
the test structure destructor is called
just before the test structure reference is set to C<undef>.
It will be passed one argument,
the test structure reference.
The return value of the test structure destructor is ignored.

Some test structures require
a destructor to be called when
they are freed.
The primary purpose for
the test structure destructor is to enable
C<Test::Weaken> to work with these data structures.

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
It can be used to prevent C<Test::Weaken> from following
and tracking individual probe references, selected by
the user.
Use of the C<ignore> argument should be avoided
when possible.
Filtering the probe references that are
returned by
L<unfreed_proberefs>
is easier, safer and
faster.
The C<ignore> argument is provided for situations
where filtering after the fact
is not practical.
One such
situation is when
large or complicated sub-objects need to be filtered out of the results.

When specified, the value of the C<ignore> argument must be a
reference to a callback subroutine.
If the reference to the callback subroutine
is C<$ignore>, C<Test::Weaken>'s call to it will be the equivalent
of C<< $ignore->($safe_copy) >>,
where C<$safe_copy> is a copy of 
a probe reference to a Perl data object.

The C<ignore> callback will be made once
for every Perl data object when it is about
to be tracked,
and once for every data object when it is about to be
followed.
The callback subroutine should return a Perl true value if the probe reference is
to a data object that should be ignored --
that is, neither followed or tracked.
Otherwise the callback subroutine should return a Perl false value.

For safety, C<Test::Weaken> does not pass its internal
probe reference
to the C<ignore> callback.
The C<ignore> callback is passed a copy of the internal
probe reference.
This prevents the user
altering
the probe reference itself.
However,
the data object referred to by the probe reference is not copied.
Everything that is referred to, directly or indirectly,
by this
probe reference
should be left unchanged by the C<ignore>
callback.
The result of modifying the probe referents might be
an exception, an abend, an infinite loop, or erroneous results.

The example above shows a common use of the C<ignore>
callback.
In this a blessed object is ignored, I<but not>
the references to it.
This is typically what is wanted when you know certain
objects are outside the contents of your test structure,
but you keep references to those objects that are part of
the contents of your test structure.
In that case, you want to know if the references are leaking,
but you do not want to see reports 
when the outside objects themselves are persistent.
Compare this with the example for the C<contents> callback below.

C<ignore> callbacks are best kept simple.
Defer as much of the analysis as you can
until after the test is completed.
C<ignore> callbacks 
can also be a significant overhead.
The C<ignore> callback is
invoked once per probe reference.

C<Test::Weaken> offers some help in debugging
C<ignore> callback subroutines.
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
It can be used to tell C<Test::Weaken> about additional
Perl data objects that need to be followed in order to find
all of the contents of the test data structure.
Use of the C<contents> argument should be avoided
when possible.
Instead of using the C<contents> argument, it is
often possible to have the constructor
create a reference to a "wrapper structure",
L<as described above in the section on nieces|Nieces>.

The C<contents> argument is for situations where the "wrapper structure"
technique is not practical.
If, for example,
creating the wrapper structure would involve a recursive
descent through the lab rat object,
using the C<contents> argument may be easiest.

When specified, the value of the C<contents> argument must be a
reference to a callback subroutine.
If the reference is C<$contents>,
C<Test::Weaken>'s call to it will be the equivalent
of C<< $contents->($safe_copy) >>,
where C<$safe_copy> is a copy of the probe reference to
another Perl reference.

The C<contents> callback is made once
for every reference, array or hash which is
about to be followed.
The C<contents> callback is not made for
Perl data objects other than references, arrays and hashes.

The example of a C<contents> above adds data objects whenever it
encounters a I<reference> to a blessed object.
Compare this with the example for the C<ignore> callback above.
Checking for references to blessed objects will not produce the same
behavior as checking for the blessed objects themselves --
there may be many references to a single
object.
Users need to be clear about the behavior they expect before implementing.

The callback subroutine will be evaluated in array context.
It should return a list of additional Perl data objects
to be followed.
This list may be empty.

For safety, C<Test::Weaken> does not pass its internal
probe reference
to the C<contents> callback.
The C<contents> callback is passed a copy of the internal
probe reference.
This prevents the user
altering
the probe reference itself.
However,
the data object referred to by the probe reference is not copied.
Everything that is referred to, directly or indirectly,
by this
probe reference
should be left unchanged by the C<contents>
callback.
The result of modifying the probe referents might be
an exception, an abend, an infinite loop, or erroneous results.

The C<contents> callbacks is
called once for every reference that it is about
to be followed.
This can be a significant overhead.

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
the return value of the C<unfreed_proberefs> method.
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
after C<Test::Weaken> was finished following the test structure reference
recursively,
but before C<Test::Weaken> called the test structure destructor or reset the
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

The C<new> method takes the same arguments as the C<leaks> method, described above.
Unlike the C<leaks> method, it always returns an B<unevaluated> tester.
An B<unevaluated> tester is one on which the test has not yet
been run and for which results are not yet available.
If there are any problems, the C<new>
method throws an exception.

The C<test> method is the only method that can be called successfully on
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
by the arguments to the C<new> constructor
and recording the results.
Throws an exception if there is a problem,
for example if the tester had already been evaluated.

The C<test> method returns the count of unfreed data objects.
This will be identical to the length of the array
returned by C<unfreed_proberefs> and
the count returned by C<unfreed_count>.

=begin Marpa::Test::Display:

## end display

=end Marpa::Test::Display:

=head1 ADVANCED TECHNIQUES

=head2 Tracing Leaks

=head3 Avoidance

C<Test::Weaken> makes tracing leaks easier, but avoidance is
still by far the best way,
and C<Test::Weaken> helps with that.
You need to use test-driven development, L<Test::More>,
modular tests in a C<t/> subdirectory,
and revision control.
These are all very good ideas for many other reasons.

Make C<Test::Weaken> part of your test suite.
Test frequently, so that when a leak occurs,
you'll have a good idea of what changes were made since
the last successful test.
Often, examining these changes is enough to
tell where the leak was introduced.

=head3 Adding Tags

The C<unfreed_proberefs> method returns an array containing
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
can be determined by using the
C<refaddr> method of
L<Scalar::Util>.
You can also obtain the referent address of a reference by adding zero
to the reference.

Note that in other Perl documentation, the term "reference address" is often
used when a referent address is meant.
Any given reference has both a reference address and a referent address.
The B<reference address> is the reference's own location in memory.
The B<referent address> is the address of the Perl data object to which the reference refers.
It is the referent address that interests us here and,
happily, it is
the referent address that both zero addition and C<refaddr> return.

=head3 Other Techniques

Sometimes, when you are interested in why an object is not being freed,
you want to seek out the reference
that keeps the object's refcount above zero.
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
For most practical programming purposes,
two indiscernable data objects can be regarded as the same object.

=head2 Debugging Ignore Subroutines

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
C<ignore> callback subroutines
are inadvertently
modifying the test structure.
The C<Test::Weaken::check_ignore> static method is
provided to make this task easier.
C<Test::Weaken::check_ignore> constructs
a debugging wrapper from
four arguments, three of which are optional.
The first argument must be the ignore callback
that you are trying to debug.
This callback is called the test subject, or
B<lab rat>.

The second, optional argument, is the maximum error count.
Below this count, errors are reported as warnings using C<Carp::carp>.
When the maximum error count is reached, an
exception is thrown using C<Carp::croak>.
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
It must be a number greater than or equal to zero.
If the compare depth is zero, the probe referent is checked
to unlimited depth.
By default the compare depth is 0.

This fourth, optional, argument is the B<reporting depth>.
It is the depth to which the probe referents are dumped
in C<check_ignore>'s error messages.
It must be a number greater than or equal to -1.
If the reporting depth is zero, the object is dumped to unlimited depth.
If the reporting depth is -1, there is no dump in the error message.
By default, the reporting depth is -1.

C<Test::Weaken::check_ignore>
returns a reference to the wrapper callback.
If no problems are detected,
the wrapper callback behaves exactly like the lab rat callback,
except that the wrapper is slower.

To discover when and if the lab rat callback is
altering its arguments,
C<Test::Weaken::check_ignore>
compares the test structure
before the lab rat is called,
to the test structure after the lab rat returns.
C<Test::Weaken::check_ignore>
compares the before and after test structures in two ways.
First, it dumps the contents of each test structure using
C<Data::Dumper>.
For comparison purposes,
the dump using C<Data::Dumper> is performed with C<Maxdepth>
set to the compare depth as described above.
Second, if the immediate probe referent has builtin type REF,
C<Test::Weaken::check_ignore>
determines whether the immediate probe referent
is a weak reference or a strong one.

If either comparison shows a difference,
the wrapper treats it as a problem, and
produces an error message.
This error message is either a C<Carp::carp> warning or a
C<Carp::croak> exception, depending on the number of error
messages already reported and the setting of the
maximum error count.
If the reporting depth is a non-negative number, the error
message includes a dump from C<Data::Dumper> of the
test structure.
C<Data::Dumper>'s C<Maxdepth>
for reporting purposes is the reporting depth as described above.

A user who wants other features, such as deep checking
of the test structure
for strengthened references,
can easily modify
C<Test::Weaken::check_ignore>.
C<Test::Weaken::check_ignore> is a static method
that does not use any C<Test::Weaken>
package resources.
It is easy to copy it from the C<Test::Weaken> source
and hack it up.
The hacked version can reside anywhere,
and does not need to
be part of the C<Test::Weaken> package.

=head1 EXPORTS

By default, C<Test::Weaken> exports nothing.  Optionally, C<leaks> may be exported.

=head1 IMPLEMENTATION DETAILS

=head2 Overview

C<Test::Weaken> first recurses through the test structure.
Starting from the test structure reference,
it follows and tracks objects recursively,
as described above.
The test structure is explored to unlimited depth,
looking for data objects to track.
Perl data objects visited during the recursion are recorded,
and no object is visited twice.
For each data object, a
probe reference is created.

Once recursion through the test structure is complete,
the probe references are weakened.
This prevents the probe references from interfering
with the normal deallocation of memory.
Next, the test structure destructor is called,
if there is one.

Finally, the test structure reference is set to C<undef>.
This should trigger the deallocation of the entire contents of the test structure.
To check that this happened, C<Test::Weaken> dereferences the probe references.
If the referent of a probe reference was deallocated,
the value of that probe reference will be C<undef>.
If a probe reference is still defined at this point,
it refers to an unfreed Perl data object.

=head2 Data Objects by Type

B<Builtin types> are
the type names returned by L<Scalar::Util>'s
C<reftype> subroutine.
C<Scalar::Util::reftype> differs from Perl's C<ref> function.
If an object was blessed into a package, C<ref> returns the package name,
while C<reftype> returns the original builtin type of the object.

=head3 ARRAY, HASH, and REF Objects

Objects of builtin type
ARRAY, HASH, and REF
are always both tracked and followed.

=head3 SCALAR and VSTRING Objects

Objects of builtin type SCALAR and VSTRING 
are tracked.
They do not hold internal references
to other Perl data objects,
so following them is meaningless.

=head3 CODE Objects

Objects of type CODE are tracked but are not followed.
This can be seen as a limitation, because
closures hold internal references to data objects.
Future versions of C<Test::Weaken> may follow CODE objects.

=head3 Objects That are Ignored

An object is said to be B<ignored> if it is neither
tracked or followed.
All objects of builtin types GLOB, IO, FORMAT and LVALUE are ignored.

The main reason
to ignore
FORMAT, IO and LVALUE objects is that
C<Data::Dumper> does not deal with
these objects gracefully.
C<Data::Dumper>
issues a cryptic warning whenever it encounters a
FORMAT, IO or LVALUE object.
Since C<Data::Dumper> is a Perl core module
in extremely wide use, this suggests that these three
objects types are, to put it mildly,
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
IO objects, which are ignored because of C<Data::Dumper> issues,
are often associated with GLOB objects.

There are other reasons to ignore FORMAT
objects.
They are always global, and therefore
can be expected to be persistent.
Use of FORMAT objects is officially deprecated.

Objects
in future implementations of Perl
may have builtin types
not described above.
They will also be ignored.

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
looks inside closures if PadWalker is present, a feature C<Test::Weaken>
does not have at present.

=head1 ACKNOWLEDGEMENTS

Thanks to jettero, Juerd and perrin of Perlmonks for their advice.
Thanks to Lincoln Stein (developer of L<Devel::Cycle>) for
test cases and other ideas.
Kevin Ryde made several important suggestions
and provided the test cases which
provided the impetus
for version 2.000000.
Kevin played the same role for version 4.000000, and provided several
important patches as well.

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
