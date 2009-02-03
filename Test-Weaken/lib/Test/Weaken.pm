package Test::Weaken;

use strict;
use warnings;

use Carp;
use Scalar::Util qw(refaddr reftype isweak weaken);

require Exporter;

use base qw(Exporter);
our @EXPORT_OK = qw(leaks poof);
our $VERSION   = '1.003_000';

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

sub Test::Weaken::Internal::follow {
    my $base_ref = shift;

    # Initialize the results with a reference to the dereferenced
    # base reference.
    my $result  = [ \( ${$base_ref} ) ];
    my %reverse = ();
    my $to_here = -1;
    REF: while ( $to_here < $#{$result} ) {
        $to_here++;
        my $refref = $result->[$to_here];
        my $type   = reftype $refref;

        my @old_refrefs = ();
        if ( $type eq 'REF' ) { @old_refrefs = ($refref) }
        elsif ( $type eq 'ARRAY' ) {
            @old_refrefs = map { \$_ } grep { ref $_ } @{$refref};
        }
        elsif ( $type eq 'HASH' ) {
            @old_refrefs = map { \$_ } grep { ref $_ } values %{$refref};
        }

        for my $old_refref (@old_refrefs) {
            my $rr_type = reftype ${$old_refref};
            my $new_refref =
                  $rr_type eq 'HASH'    ? \%{ ${$old_refref} }
                : $rr_type eq 'ARRAY'   ? \@{ ${$old_refref} }
                : $rr_type eq 'REF'     ? \${ ${$old_refref} }
                : $rr_type eq 'SCALAR'  ? \${ ${$old_refref} }
                : $rr_type eq 'CODE'    ? \&{ ${$old_refref} }
                : $rr_type eq 'VSTRING' ? \${ ${$old_refref} }
                :                         undef;
            if ( defined $new_refref and not $reverse{ $new_refref + 0 } ) {
                push @{$result}, $new_refref;
                $reverse{ $new_refref + 0 }++;
            }
        }

    }    # REF

    return $result;

}    # sub follow

# See POD, below
sub new {
    my ( $class, $arg1, $arg2 ) = @_;
    my $constructor;
    my $destructor;
    my $self = {};
    bless $self, $class;

    UNPACK_ARGS: {
        if ( ref $arg1 eq 'CODE' ) {
            $self->{constructor} = $arg1;
            if ( defined $arg2 ) {
                $self->{destructor} = $arg2;
            }
            return $self;
        }

        if ( ref $arg1 ne 'HASH' ) {
            croak('arg to Test::Weaken::new is not HASH ref');
        }

        if ( defined $arg1->{constructor} ) {
            $self->{constructor} = $arg1->{constructor};
            delete $arg1->{constructor};
        }

        if ( defined $arg1->{destructor} ) {
            $self->{destructor} = $arg1->{destructor};
            delete $arg1->{destructor};
        }

        my @unknown_named_args = keys %{$arg1};

        if (@unknown_named_args) {
            croak(
                'Unknown named args to Test::Weaken::new: ',
                ( join q{ }, @unknown_named_args )
            );
        }

    }    # UNPACK_ARGS

    croak('Test::Weaken: constructor must be CODE ref')
        unless ref $self->{constructor} eq 'CODE';

    croak('Test::Weaken: destructor must be CODE ref')
        unless ref $self->{destructor} eq 'CODE';

    return $self;

}    # sub new

sub test {

    my $self        = shift;
    my $constructor = $self->{constructor};
    my $destructor  = $self->{destructor};

    my $test_object_rr = \( $constructor->() );
    if ( not ref ${$test_object_rr} ) {
        carp(
            'Test::Weaken test object constructor did not return a reference'
        );
    }
    my $refrefs = Test::Weaken::Internal::follow($test_object_rr);

    $self->{probe_count} = @{$refrefs};
    $self->{original_weak_count} =
        grep { ref $_ eq 'REF' and isweak ${$_} } @{$refrefs};
    $self->{original_strong_count} =
        $self->{probe_count} - $self->{original_weak_count};

    for my $refref ( @{$refrefs} ) {
        weaken($refref);
    }

    # Now free everything.
    $destructor->( ${$test_object_rr} ) if defined $destructor;

    $test_object_rr = undef;

    my $unfreed_proberefs = [ grep { defined $_ } @{$refrefs} ];
    $self->{unfreed_proberefs} = $unfreed_proberefs;

    return scalar @{$unfreed_proberefs};

}    # sub test

sub Test::Weaken::Internal::poof_array_return {

    my $test    = shift;
    my $results = $test->{unfreed_proberefs};

    my @unfreed_strong = ();
    my @unfreed_weak   = ();
    for my $refref ( @{$results} ) {
        if ( ref $refref eq 'REF' and isweak ${$refref} ) {
            push @unfreed_weak, $refref;
        }
        else {
            push @unfreed_strong, $refref;
        }
    }

    # See the POD on the return values
    return ( @{$test}{qw(original_weak_count original_strong_count)},
        \@unfreed_weak, \@unfreed_strong );

} ## end sub poof_array_return;

sub poof {
    my @args   = @_;
    my $test   = new Test::Weaken(@args);
    my $result = $test->test();
    return Test::Weaken::Internal::poof_array_return($test) if wantarray;
    return $result;
}

sub leaks {
    my @args   = @_;
    my $test   = new Test::Weaken(@args);
    my $result = $test->test();
    return $test if $result;
    return;
}

sub unfreed_proberefs {
    my $test   = shift;
    my $result = $test->{unfreed_proberefs};
    if ( not defined $result ) {
        croak('Results not available for this Test::Weaken object');
    }
    return $result;
}

sub unfreed_count {
    my $test   = shift;
    my $result = $test->{unfreed_proberefs};
    if ( not defined $result ) {
        croak('Results not available for this Test::Weaken object');
    }
    return scalar @{$result};
}

sub probe_count {
    my $test  = shift;
    my $count = $test->{probe_count};
    if ( not defined $count ) {
        croak('Results not available for this Test::Weaken object');
    }
    return $count;
}

sub original_weak_count {
    my $test  = shift;
    my $count = $test->{original_weak_count};
    if ( not defined $count ) {
        croak('Results not available for this Test::Weaken object');
    }
    return $count;
}

sub original_strong_count {
    my $test  = shift;
    my $count = $test->{original_strong_count};
    if ( not defined $count ) {
        croak('Results not available for this Test::Weaken object');
    }
    return $count;
}

1;

__END__

=head1 NAME

Test::Weaken - Test that freed references are, indeed, freed

=head1 SYNOPSIS

    use Test::Weaken qw(leaks);
    use Data::Dumper;
    use Math::BigInt;
    use Math::BigFloat;

    my $good_test = sub {
       my $obj1 = new Math::BigInt('42');
       my $obj2 = new Math::BigFloat('7.11');
       [ $obj1, $obj2 ];
    };  

    my $bad_test = sub {
       my $array = [ 42, 711 ];
       push @{$array}, $array;
       $array;
    };

    my $bad_destructor = sub { "I don't work" };

    if ( !leaks( $good_test ) ) {
        print "No leaks in test 1\n";
    } else {
        print "There were memory leaks from test 1!\n";
    }

    my $test = Test::Weaken::leaks({
        constructor => $bad_test,
        destructor  => $bad_destructor,
    });
    if ( $test ) {
        my $unfreed_proberefs = $test->unfreed_proberefs();
        my $unfreed_count = @{$unfreed_proberefs};
        printf "Test 2: %d of %d original references were not freed\n",
            $test->unfreed_count(),
            $test->probe_count();
        print "These are the probe references to the unfreed objects:\n";
        for my $proberef ( @{$unfreed_proberefs} ) {
            print Data::Dumper->Dump( [$proberef], ['unfreed'] );
        }
    }

=head1 DESCRIPTION

Memory leaks happen when the memory allocated by objects which are no longer needed is not completely deallocated.
(Deallocating memory is also called B<freeing> it.)
As an example in Perl, a memory leak will occur if
an object contains circular references and does not have an effective scheme for
weakening references or cleaning up memory.
Leaked memory is a useless overhead.
Leaky memory objects can significantly impact system performance.
They can also cause the application with the leaks to abend due to lack of memory.

C<Test::Weaken> allows you to check that an object does not leak memory.
If it does leak memory, C<Test::Weaken> allows you to examine the "leaked" memory objects,
even objects that would usually be inaccessible.
It performs this magic by creating a set of weakened B<probe references>, as explained L<below|/"IMPLEMENTATION">.

The test object is passed as the return value of a closure.
The closure should return the B<primary test reference>,
a reference to the B<test object>.
C<Test::Weaken> checks the memory that can be found by following the primary test reference.
Starting with the primary test reference,
arrays, hashes, weak references and strong references are followed
recursively and to unlimited depth.

C<Test::Weaken> handles circular references gracefully.
A major purpose of C<Test::Weaken> is to test schemes for
circular references.
To avoid infinite loops,
C<Test::Weaken> records all the memory objects it visits,
and will not visit the same memory object twice.

=head2 Why the Test Object is Passed via a Closure

C<Test::Weaken> does not accept its test object or its primary test reference
directly as an argument.
Instead, C<Test::Weaken> receives its test objects from B<test object constructors>.

Why so roundabout?
It turns out the indirect way is the easiest.
The test object must not have any strong references to
it from outside.
It takes some craft
to create the test object
in C<Test::Weaken>'s calling environment
without leaving
any reference to the test object in the calling environment,
and it is easy to make a mistake.

When the calling environment retains a reference to memory contained in the test object,
the result is a memory leak.
Mistakes in setting up the test object, therefore,
appear as false reports of memory leaks.
These are hard to distinguish from the real thing.

Memory objects local to a closure will be destroyed when the
closure returns, and any references they held will be released.
When the test object is set up entirely in a closure, using only memory
objects local to that closure,
it becomes relatively easy to be sure that nothing is left behind
that will hold an unintended reference to memory inside the test
object.

To encourage this discipline,
C<Test::Weaken> requires that its primary test reference
be the return value of a closure.
This makes what is the safe and almost always right thing to do,
also the easiest thing to do.

Of course, if the user wants to,
within the closure
he can refer to data in global and other scopes from outside the closure.
The user can also return memory objects created partially or completely from data in any or all
of those scopes.
Subverting C<Test::Weaken>'s "closure data only" discipline can be done with only a small amount of trouble,
certainly by comparison to the grief that the user is exposing himself to.

=head2 Returns and Exceptions

The methods of C<Test::Weaken> do not return errors.
Errors are always thrown as exceptions.

=head1 METHODS

=head2 leaks

Arguments to the C<leaks> static method may be passed as a reference to
a hash of named arguments,
or directly as code references.
C<leaks> returns a C<Test::Weaken> object if it found leaks,
and a Perl false value otherwise.
Users simply wanting to know if there were leaks can check whether
the return value of C<leaks> is a Perl true or false.
Users who want to look more closely at leaks can use other methods
to interrogate the return value.

A B<test object constructor> is a required argument.
It must be a code reference.
If passed directly, it must be the first argument to C<leaks>.
Otherwise, it must be the value of the C<constructor> named argument.

The test object constructor 
should build the B<test object>
and create a B<primary test reference> to it.
The return value of the test object constructor must be
the primary test reference.
It is best to construct the test object
inside the test object constructor
as much as possible.
That is the easiest way to construct a
test object with no references into it from the
calling environment.

The B<test object destructor> is an optional argument.
If specified, it must be a code reference.
If passed directly, it must be the second argument to C<leaks>.
Otherwise, it must be the value of the C<destructor> named argument.

If specified,
the test object destructor is called
just before the primary test reference is undefined.
It will be passed one argument,
the primary test reference.
One purpose for
the test object destructor is to allow
C<Test::Weaken> to work with objects
that require a destructor to be called on them when
they are freed.
For example, some of the objects created by Gtk2-Perl are of this type.

=head2 unfreed_proberefs

Returns a reference to an array of probe references to the unfreed memory objects.
The user may examine these to find the source of a leak,
or to produce her own statistics.

The array is returned as a reference because in some applications it can be quite long.
The array contains probe references, not the memory objects themselves.
This is because some memory objects, such as other arrays and hashes, cannot be elements of arrays.
Weak references are another reason for not returning an array containing the memory objects themselves.
Directly copying the weak references would strengthen them.

=head2 unfreed_count

Returns the count of unfreed memory objects.
This count will be exactly the length of the array referred to by
the return value of the C<unfreed_proberefs> method.

=head2 probe_count

Returns the total number of probe references in the test,
including references to freed memory objects.
This is the count of probe references
after C<Test::Weaken> was finished following the test object reference
recursively,
but before it called the test object destructor and undefined the
test object reference.

=head1 ADVANCED TECHNIQUES

The simplest way to use C<Test::Weaken> is to call the C<leaks>
method, and treat its return value as a Perl true or false.
But you can also use C<Test::Weaken> for tracing leaks.
Here are some potentially helpful techniques.

=head2 Tracing Memory Leaks

The C<unfreed_proberefs> method returns an array containing the unfreed
memory objects and
can be used
to find the source of leaks.
If circumstances allow you to
add elements to the arrays and hashes,
you might find it useful to "tag" them for tracking purposes.

You can uniquely identify memory objects using
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
The reference address is the reference's own location in memory.
The referent address is the address of the memory object to which it refers.
It is the referent address that interests us here and, happily, it is 
the referent address that addition of zero and C<refaddr> return.

=head2 Testing Objects Which Refer to Persistent or External Memory

Your test object may refer to
memory that is considered to be "outside" the object:
B<external memory>.
In other cases, the specification of the object may allow certain memory referred
to by the object to persist after the object is destroyed:
B<persistent memory>.
External memory is often expected to be persistent memory.

To check for leaks in objects which refer to persistent memory,
you can examine the unfreed objects returned by C<unfreed_proberefs>
and eliminate the memory objects which are persistent.
The remaining objects will be the memory leaks.

=head2 If You Really Must Test Deallocation of a Global

As explained above, C<Test::Weaken> receives its test object as the return
value of a closure.
It does this because it's tricky to create objects in a global
environment without keeping references to them.
References accidently held by the calling environment will cause false leak reports.

But you may have no other choice.
The test object constructor can refer to data
in a scope which is not local
to the constructor.
It can also return a primary test reference built using this
data.
Nothing prevents a test object constructor from, for example,
simply returning a reference it finds in global scope as the
primary test reference.

=head1 EXPORT

By default, C<Test::Weaken> exports nothing.  Optionally, C<leaks> may be exported.

=head1 LIMITATIONS

C<Test::Weaken> does not check for leaked code references or look inside them.

=head1 IMPLEMENTATION

C<Test::Weaken> first recurses through the test object.
It follows all weak and strong references, arrays and hashes.
The test object is explored to unlimited depth, 
looking for B<memory objects>, that is, objects which have memory allocated.
Visited memory objects are tracked,
and no memory object is visited twice.
For each memory object, a
B<probe reference> is created.

Once recursion through the test object is complete,
the probe references are weakened,
so that they will not interfere with normal deallocation of memory.
Next, the test object destructor is called,
if there is one.

Finally, the primary test reference is undefined.
This should trigger the complete deallocation of all memory held by the test object.
To check that this happened, C<Test::Weaken> dereferences the probe references.
If the referent of a probe reference was deallocated,
the value of that probe reference will be C<undef>.
If a probe reference is still defined at this point,
it refers to an unfreed memory object.

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
L<Devel::Cycle>, which examine existing structures non-destructively.
L<Devel::Leak> also covers similar ground, although it requires
Perl to be compiled with C<-DDEBUGGING> in order to work.  L<Devel::Cycle>
looks inside closures if PadWalker is present, a feature C<Test::Weaken>
does not have at present.

=head1 ACKNOWLEDGEMENTS

Thanks to jettero, Juerd and perrin of Perlmonks for their advice.
Thanks to Lincoln Stein (developer of L<Devel::Cycle>) for
test cases and other ideas.

After the first release of C<Test::Weaken>,
Kevin Ryde made several important suggestions
and provided test cases.
These provided the impetus for version 2.000000.

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
