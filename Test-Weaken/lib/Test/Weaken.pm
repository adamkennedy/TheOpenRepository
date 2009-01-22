package Test::Weaken;

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(poof);
our $VERSION   = '1.001_000';
$VERSION   = eval $VERSION;

use warnings;
use strict;

use Carp;
use Scalar::Util qw(refaddr reftype isweak weaken);

=begin Implementation:

The basic strategy: get a list of all the references, attempt to
free the memory, and check the references.  If the memory is free,
they'll be undefined.

References to be tested are kept as references to references.  For
convenience, I will call these ref-refs.  They're necessary for
testing both weak and strong references.

If you copy a weak reference, the result is a strong reference.
There may be good reasons for it, but that behavior is a big problem
for this module.  Copying is difficult to avoid because a lot of
useful Perl constructs copy their arguments implicitly.  Creating
strong refs to the weak refs allows the code to avoid directly
manipulating the weak refs, ensuring they stay weak.

In dealing with strong references, I also need references to
references, but for a different reason.  In keeping the strong
references around to test that they go to undefined when released,
there's a Heisenberg paradox or, less pretentiously, a
chicken-and-egg situation.  As long as there is an unweakened
reference, the memory will not be freed.  The solution?  Create
references to the strong references, and before the test, weaken
the first layer of references.  The weak refs will allow their
strong refs to be freed, but the defined-ness of the strong refs
can still be tested via the weak refs.

=end Implementation:

=cut

# See POD, below
sub poof {

    my $constructor    = shift;
    my $destructor     = shift;

    my $type = reftype $constructor;
    croak('poof() first argument must be code ref') unless $type eq 'CODE';

    if (defined $destructor)
    {
        $type = reftype $destructor;
        croak('poof() arguments must be code refs') unless $type eq 'CODE';
    }

    my $base_ref = $constructor->();
    $type = ref $base_ref;
    carp("poof() argument did not return a reference") unless $type;

    # reverse hash -- maps strong ref address back to a reference to the reference
    my $reverse = {};

    # the current working set -- initialize to our first ref
    my $workset = [ \$base_ref ];

    # an array of strong references to the weak references
    my $weak = [];
    my $strong = [];

    # Loop while there is work to do
    WORKSET: while (@$workset) {

        # The "follow-up" array, which holds those ref-refs to be 
        # be worked on in the next pass.
        my $follow = [];

        # For each ref-ref in the current workset
        REF: for my $rr (@$workset) {
            my $type = reftype $$rr;

            # If it's not a reference, nothing to do.
            next REF unless defined $type;

            # We push weak refs into a list, then we're done.
            # We don't follow them.
            if ( isweak $$rr) {
                push( @$weak, $rr );
                next REF;
            }

            # Put it into the list of strong refs
            push(@$strong, $rr);

            # If we've followed another ref to the same place before,
            # we're done
            if ( defined $reverse->{ refaddr $$rr } ) {
                next REF;
            }

            # If it's new, first add it to the hash
            $reverse->{ refaddr $$rr } = $rr;

            # Note that this implementation ignores refs to closures

            # If it's a reference to an array
            if ( $type eq "ARRAY" ) {

                # Index through its elements to avoid
                # copying any which are weak refs
                ELEMENT: for my $ix ( 0 .. $#$$rr ) {

                    # Obviously, no need to deal with non-existent elements
                    next ELEMENT unless exists $$rr->[$ix];

                    # If it's defined, put it on the follow-up list
                    if ( defined $$rr->[$ix] ) {
                        push( @$follow, \( $$rr->[$ix] ) );
                    }
                    else {
                        # Not defined (but exists)
                        # Set it to a number so it doesn't fool us later
                        # when we check to see that it was freed
                        #
                        # Actually, I think this is unnecessary.
                        # Only references can fool us, and if it's undef
                        # it's not a reference.
                        # $$rr->[$ix] = 42;
                    }
                }
                next REF;
            }

            # If it's a reference to a hash
            if ( $type eq "HASH" ) {

                # Iterate through the keys to avoid copying any values which are weak refs
                for my $ix ( keys %$$rr ) {

                    # If it's defined, put it on the follow-up list
                    if ( defined $$rr->{$ix} ) {
                        push( @$follow, \( $$rr->{$ix} ) );
                    }
                    else {
                        # Hash entry exists but is undef
                        # Set it to a number so it doesn't fool us later
                        # when we check to see that it was freed
                        #
                        # Actually, I think this is unnecessary.
                        # Only references can fool us, and if it's undef
                        # it's not a reference.
                        # $$rr->{$ix} = 42;
                    }
                }
                next REF;
            }

            # If it's a reference to a reference,
            # put a reference to the reference to a reference (whew!)
            # on the follow up list
            if ( $type eq "REF" ) {
                push( @$follow, \$$$rr );
            }

        } # REF

        # Replace the current work list with the items we scheduled
        # for follow up
        $workset = $follow;

    }    # WORKSET

    # For the strong ref-refs, weaken the first reference so the array
    # of strong references does not affect the test
    for my $rr (@$strong) {
        weaken( $rr );
    }

    # Record the original counts of weak and strong references
    my $weak_count   = @$weak;
    my $strong_count = @$strong;

    # Now free everything.  Note the weaken of the base_ref --
    # it's necessary so that the counts work out right.
    $reverse = undef;
    $workset = undef;
    $destructor->($base_ref) if defined $destructor;
    weaken($base_ref);

    # The implicit copy below will strengthen the weak references
    # but it no longer matters, since we have our data
    my @unfreed_strong = map {$$_} grep { defined $$_ } @$strong;
    my @unfreed_weak   = map {$$_} grep { defined $$_ } @$weak;

    # See the POD on the return values
    return
        wantarray
        ? ( $weak_count, $strong_count, \@unfreed_weak, \@unfreed_strong )
        : ( @unfreed_weak + @unfreed_strong );

} ## end sub poof

1;

=head1 NAME

Test::Weaken - Test that freed references are, indeed, freed

=head1 SYNOPSIS

    use Test::Weaken qw(poof);

    my $test = sub {
           my $obj1 = new Module::Test_me1;
           my $obj2 = new Module::Test_me2;
           [ $obj1, $obj2 ];
    };  

    my $unfreed_count = Test::Weaken::poof( $test );

    my ($weak_count, $strong_count, $weak_unfreed, $strong_unfreed)
        = Test::Weaken::poof( $test );

    print scalar @$weak_unfreed,
        " of $weak_count weak references freed\n";
    print scalar @$strong_unfreed,
        " of $strong_count strong references freed\n";

    print "Weak unfreed references: ",
        join(" ", map { "".$_ } @$weak_unfreed), "\n";
    print "Strong unfreed references: ",
        join(" ", map { "".$_ } @$strong_unfreed), "\n";

=head1 DESCRIPTION

Frees memory, and
checks that the memory
is deallocated.
The memory checked includes all memory referred to indirectly,
whether through arrays, hashes, weak references or strong references.
Arrays, hashes and references are followed
recursively and to unlimited depth.

Circular references are handled 
gracefully.
In fact,
a major purpose of C<Test::Weaken> is to test schemes for
deallocating circular references.

=head1 METHOD

=head2 poof

The C<poof> static method
takes one or two closures as arguments.
The first, required, argument is the B<test object constructor>
for the object to be tested.
The second, optional, argument is a B<test object destructor>.

The test object constructor,
sometimes simply called the B<constructor> when no confusion
with other constructors will arise,
should build the B<test object>
and create a B<primary test reference> to it.
The return value of the test object constructor must be
the primary test reference.
It is usually best to construct the test object
inside the test object constructor
as much as possible.
That is the easiest way to construct a
test object with no references into it from C<poof>'s
calling environment.
More on this below.

The test object destructor is optional.
The test object destructor will be called just before C<Test::Weaken>
frees the primary test reference.
The destructor is called with
the primary test reference as its only argument,
just before the primary test reference is freed.
The test object destructor can be used to allow
C<Test::Weaken> to work with objects
that require a destructor to be called on them before
they are freed.
For example, some of the objects created by Gtk2-Perl are of this type.
If no test object destructor is specified, no last minute processing
will be done on the primary test reference before it is freed.

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

In scalar context,
C<poof> returns the number of unfreed test references.
If all memory was deallocated successfully, this number will be zero.

In array context, C<poof>
returns a list
with four elements.
First, the starting count of weak references.
Second, the starting count of strong references.
Third, a reference
to an array containing references to the unfreed weak references.
Fourth, a reference to an array containing references to the unfreed
strong references.

If C<@result> is the result array from a call to C<poof>,
then the number of strong references that were freed can be calculated
as

    $result[1] - @{$result[3]}

that is,
the starting count of strong references,
less the size of the array containing the unfreed strong references.
Similarly, the count of freed weak references will be

    $result[0] - @{$result[2]}

The unfreed references in the arrays can be dereferenced
and the unfreed data examined.
This may offer a clue to locate the source of a memory leak.

=head2 Why the Arguments are Closures

Obtaining the primary test reference
from a test object constructor
may seem
roundabout.
In fact, this indirect method is the easiest.
The test object must not have any strong references to
it from outside.
It takes some craft
to create and pass an object without holding
a reference to it.
Mistakes are easy to make.
If a mistake were made, and C<poof>'s calling environment held
a strong reference into the test object,
not all memory would be freed.
If this happened by accident,
so that the programmer was not aware of what was going on,
the effect would be a false negative.
Errors like this are tricky to detect and
hard to debug.

When the test object is constructed completely within the test object constructor,
and all the objects used to construct
it are also in the scope of the test object constructor, 
there will be
no strong references held from outside the test object
once the test object constructor returns.
Following this discipline, it is relatively easy
for a careful programmer to avoid false negatives.

=head2 Tricks and Techniques

In scalar context C<poof> returns zero if all references were freed.
This is the simplest way to use C<poof>,
but sometimes special techniques are required.

=head3 Objects Which Refer to External Memory

The object you need to test may have references to "external" memory --
memory consider "outside" the object and not intended to be freed when
the object is.
When this is the case several techniques are be used.

First, if you can rely there being a fixed count of "external" references,
you can call C<poof> in scalar context and check that the correct count is
returned.  Be aware that this can cause false positives in cases where equal numbers of
references which shouldn't be freed
are freed and references which should be freed are not.

Second, you can call
C<poof> in array context, so that it returns lists of the unfreed references.
The unfreed references can be then be checked to ensure all and only the correct
references are not freed.
If references can't be identified using their contents,
the addresses of the references can be recorded beforehand
and afterward, and compared.

=head3 Tracing Memory Leaks

C<poof> called in array context can also be used
to find the source of memory leaks.
Pointer address can be used to identified which references are being
"leaked".
Depending on the application,
you can also add elements to
arrays and hashes to "tag" them for this purpose.

=head3 If You Really Must Test Deallocation of a Global

As explained above, C<poof> takes its test object as the the return
value from a closure because it's tricky to create objects in the global
environment without holding references to them which will cause false negatives.
If you really have no choice but to do use a reference to an object
from the global environment,
you can defeat C<poof>'s safeguards by specifying
as C<poof>'s constructor argument a closure which
return the reference to the global object.

=head1 EXPORT

By default, C<Test::Weaken> exports nothing.  Optionally, C<poof> may be exported.

=head1 LIMITATIONS

C<Test::Weaken> does not look inside code references.

=head1 IMPLEMENTATION

=head2 C<poof>'s Name

The name C<poof> is intended to warn the programmer that the test
is destructive.  I originally called the main subroutine C<destroy>,
but that choice seemed unfortunate because of similarities to
C<DESTROY>, a name reserved for object destructors.

=head2 How C<poof> Works

C<Test::Weaken> first recurses through the test object.
It follows all weak and strong references, arrays and hashes.
The test object is explored to unlimited depth.
Visited references are tracked, and no reference is visited
twice.
Two lists of test references into the original data are generated.
One list is of strong test references and the other is of weak test references.

As it recurses,
C<Test::Weaken> creates a B<probe reference> for every test
reference.
The probe references to the strong test references are weakened,
so that the probe reference will not interfere with normal deallocation of memory.

When all the probe references have been created,
the primary test reference is weakened.
Normally, this causes the test object to be deallocated.
To check this, C<Test::Weaken> dereferences the probe references.
If the referent of a probe reference was deallocated,
the value of that probe reference will be C<undef>.

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
Thanks also to Lincoln Stein (developer of L<Devel::Cycle>) for
test cases and other ideas.

=head1 COPYRIGHT & LICENSE

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
