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
        carp('poof() argument did not return a reference');
    }
    my $refrefs = Test::Weaken::Internal::follow($test_object_rr);

    $self->{original_ref_count} = @{$refrefs};
    $self->{original_weak_count} =
        grep { ref $_ eq 'REF' and isweak ${$_} } @{$refrefs};
    $self->{original_strong_count} =
        $self->{original_ref_count} - $self->{original_weak_count};

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

sub original_ref_count {
    my $test  = shift;
    my $count = $test->{original_ref_count};
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

    my $bad_destructor = sub { "I don't work right" };

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
        my $unfreed = $test->unfreed_proberefs();
        my $unfreed_count = @{$unfreed};
        printf "Test 2: %d of %d original references were not freed\n",
            $test->unfreed_count(),
            $test->original_ref_count();
        print "These are the probe references to the unfreed objects:\n";
        for my $probe_ref ( @{$unfreed} ) {
            print Data::Dumper->Dump( [$probe_ref], ['unfreed'] );
        }
    }

=head1 DESCRIPTION

A memory leak happens when an object is incompletely freed.
In Perl this happens, for example, if the object contains circular references which are not
properly weakened or cleaned up.
Leaked memory is often inaccessible, but it still uses space, and repeated creation and destruction
of leaky memory objects can and does cause failures due to lack of memory.

C<Test::Weaken> allows you to check that an object does not leak memory.
If it does leak memory, C<Test::Weaken> allows you to examine the "leaked" memory objects,
even objects that would be "inaccessbile".
It performs this magic by creating its own set weak references, as explained below.

The test object is passed using a closure.
The closure should return a reference to the object to be checked.
Memory referred to by this reference is checked.
Arrays, hashes, weak references and strong references are followed
recursively and to unlimited depth.

C<Test::Weaken> handles circular references gracefully.
This is important, because a major purpose of C<Test::Weaken> is to test schemes for deallocating
circular references.
To avoid infinite loops,
C<Test::Weaken> records all the references it visits,
and will not follow the same reference twice.

=head2 Why the Arguments are Closures

C<Test::Weaken> does not accept it's test objects as
arguments directly.
C<Test::Weaken>'s requires the test object be passed
indirectly, using a B<test object constructor>.
The test object constructor is passed as reference to a closure
which returns a reference to the test object.
Internally, C<Test::Weaken> calls the test object constructor
to get the object to be tested.

Why so roundabout?
It turns out that this indirect method is the easiest.
The test object must not have any strong references to
it from outside.
If you create the test object in C<Test::Weaken>'s
calling environment,
it takes some craft
to create object without leaving
any reference to it in that calling environment.

It is easy to leave a reference from the calling environment
in the object by mistake.
Easy to make the mistake, but hard to detect and debug it.
Mistakes appear as false reports of memory leaks.

When a test object is constructed completely within the test object constructor,
it is easy to keep all the objects used to construct that test object
in the scope of the test object constructor.
By following this discipline, 
you can relatively easily be sure
that all the references to memory objects used in building the test object
are released which
the test object constructor returns.
In C<Test::Weaken>'s case, roundabout turned out to be the fastest approach.

=head2 Returns and Exceptions

The methods of C<Test::Weaken> do not return errors.
Errors are always thrown as exceptions.

=head1 METHODS

=head2 leaks

Argments to the C<leaks> static method may be passed as a reference to
a hash of named arguments,
or directly as code references.

C<leaks> returns a C<Test::Weaken> object if it found leaks,
otherwise a Perl false value.
Users simply wanting to know if there were leaks can check whether
the return value of C<leaks> is a Perl true or false.
Users who want to look more closely at leaks can use other methods
to interrogate the return value.
Errors are thrown as exceptions.

A B<test object constructor> is a required argument.
It must be a code reference.
If passed directly, it must be the first argument to C<leaks>.
Otherwise, it must be the C<constructor> named argument.

The B<test object destructor> is an optional argument.
If specified, it must be a code reference.
If passed directly, it must be the second argument to C<leaks>.
Otherwise, it must be the C<destructor> named argument.

The test object constructor 
should build the B<test object>
and create a B<primary test reference> to it.
The return value of the test object constructor must be
the primary test reference.
It is usually best to construct the test object
inside the test object constructor
as much as possible.
That is the easiest way to construct a
test object with no references into it from the
calling environment.
I discuss this more below.

The optional test object destructor
is called just before C<Test::Weaken>
frees the primary test reference.
If specified,
the test object destructor is called with
the primary test reference as its only argument,
just before the primary test reference is undefined.
The test object destructor can be used to allow
C<Test::Weaken> to work with objects
that require a destructor to be called on them before
they are freed.
For example, some of the objects created by Gtk2-Perl are of this type.

=head2 unfreed_proberefs

Returns a reference to an array of references to the unfreed test references.
The user may examine these to find the source of a leak,
or to produce her own statistics about the memory leaks.

The array is returned as a reference because in some applications it can be quite long.
The array contains references to the test references, not the test references themselves,
because the test references may be weak references, and directly copying them would strengthen them.

At present, there is only the "raw" version of the unfreed array.
In the future, I may add calls that "cook" the unfreed array of references,
for examply, by pruning some of the unfreed references referred to indirectly 
by others in the array.

=head2 unfreed_count

Returns the count of unfreed test references.
This count will be exactly the length of the array referred to by
the return value of the C<unfreed_proberefs> method.

=head2 original_ref_count

Returns the count of test references.
This is the count after Test::Weaken finished following the test object reference
recursively, and before calling the test object destructor and undef'ing the
test object reference.

By recursively
following references, arrays, and hashes
from the primary test reference, C<poof>
finds all of the references in the test object.
These are C<poof>'s B<test references>.
In recursing through the test object,
C<poof> keeps track of visited references.
C<poof> never visits the same reference twice,
and therefore has no problem
when it has to deal with a test object which contains circular references.

=head1 ADVANCED TECHNIQUES

The simplest way to use C<Test::Weaken> is to call the C<leaks>
method, and treat its return value as a true or a false.
But you might want to use C<Test::Weaken> as a true for tracing leaks
if they exist.
Here are some potentially helpful techniques.

=head2 Tracing Memory Leaks

The C<unfreed_proberefs> method returns an array containing the unfreed
memory and
can be used
to find the source of leaks.
There are several techniques for determining what the leaks are.

If it's obvious what the leaked objects are and where they came from,
you're in luck.
If circumstances make it reasonable to
add elements to the arrays and hashes,
you might find it useful to "tag" them for tracking purposes.

If all else fails, you
can identify memory with reference addresses.
A reference's address 
can be determined by using L<Scalar::Util>'s C<refaddr>.
You can also find a reference's address by adding zero
to the reference.

=head2 Objects Which Refer to External Memory

Your test object may have references to "external" memory --
memory considered "outside" the object.
This kind of "external" memory will often be expected to persist even
after the test object is freed.
To check for leaks when this is the case,
you can examine the unfreed objects returned by C<unfreed_proberefs>.
Once you eliminate the correctly unfreed objects from the list returned
by C<unfreed_proberefs>, the remaining objects will be memory leaks.

=head2 If You Really Must Test Deallocation of a Global

As explained above, C<poof> takes its test object as the the return
value from a closure because it's tricky to create objects in the global
environment without holding references to them.
References accidently held by the calling environment will cause false leak reports.

It is easy to accidently cause false leak reports when you
create objects in the global environment and very hard to debug this.
But you can write a test object constructor that returns
any object that is in a visible scope.
So if you belive that you really have no other choice,
your test object constructor can return
a reference to a global object.

=head1 EXPORT

By default, C<Test::Weaken> exports nothing.  Optionally, C<leaks> may be exported.

=head1 LIMITATIONS

C<Test::Weaken> does not check for leaked code references or look inside them.

=head1 IMPLEMENTATION

=head2 How C<Test::Weaken> Works

C<Test::Weaken> first recurses through the test object.
It follows all weak and strong references, arrays and hashes.
The test object is explored to unlimited depth, 
looking for B<memory objects>, objects which have memory allocated.
Visited memory objects are tracked, and no memory object is followed
twice.
For each memory object, a
B<probe reference> is created.

Once recursion through the test object is complete,
the probe references are weakened,
so that they will not interfere with normal deallocation of memory.
Next, the test object destructor is called,
if the user specified one.

Finally, the primary test reference is undefined.
This should complete deallocation of memory held by the test object.
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
These totally altered the design of this module,
and provided the impetus for version 2.000000.

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
