package ADAMK::Lacuna::Bot::MoveResources;

use 5.008;
use strict;
use warnings;
use List::Util                 ();
use Params::Util               ();
use ADAMK::Lacuna::Bot::Plugin ();

our $VERSION = '0.01';
our @ISA     = 'ADAMK::Lacuna::Bot::Plugin';

use constant HOUR  => 3600;
use constant TYPES => qw{ food ore water energy };

sub run {
    my $self   = shift;
    my $client = shift;
    my $empire = $client->empire;

    # Precalculate which planet/resource combinations are in excess
    # and which planet/resource combinations have excess space.
    my @from = ();
    my @to   = ();
    foreach my $planet ( $empire->planets ) {
        my $name = $planet->name;
        $self->trace("Checking planet $name");

        # Can we accept surplus resources?
        foreach my $type ( TYPES ) {
            # Get resource information
            my $space_method = "${type}_space";
            my $hour_method  = "${type}_hour";
            my $space        = $planet->$space_method();
            my $hour         = $planet->$hour_method();

            # How much can we accept from elsewhere
            if ( $hour > 0 ) {
                $space = $space - (4 * $hour);
                $space = 0 if $space < 0;
            } else {
                # Just go with the space there now
            }
            if ( $space > 0 ) {
                my $hours = int($space / $hour) + 1;
                push @to, {
                    planet_id => $planet->body_id,
                    name      => $name,
                    type      => $type,
                    hour      => $hour,
                    space     => $space,
                };
            }

            # How much can we send to elsewhere
            if ( $hour > 0 ) {
                my $remaining_method = "${type}_remaining";
                my $remaining        = $planet->$remaining_method();
                if ( $remaining < 4 ) {
                    # Always keep an emergency buffer
                    my $stored_method = "${type}_stored";
                    my $stored        = $planet->$stored_method() - 10000;
                    $stored = 0 if $stored < 0;

                    # Check shipping as late as possible to reduce API calls
                    if ( $stored and $planet->cargo_ship ) {
                        push @from, {
                            planet_id => $planet->body_id,
                            name      => $name,
                            type      => $type,
                            hour      => $hour,
                            space     => $space,
                            stored    => $stored,
                            remaining => $remaining,
                        };
                    }
                }
            }
        }
    }

    # Sort the supply and demand options
    my @priority = $empire->resource_priority;
    my %types    = map { $priority[$_] => $_ } ( 0 .. $#priority );

    # Print a summary of our options
    $self->trace("Options:");
    foreach ( @from ) {
        $self->trace("Supply - $_->{name} - $_->{stored} $_->{type}, $_->{remaining}hr storage");
    }
    foreach ( @to ) {
        my $hours = int($_->{space} / $_->{hour});
        $self->trace("Accept - $_->{name} - $_->{space} $_->{type}, ${hours}hr excess");
    }

    # Attempt to clear the overflowing resources
    while ( @from ) {
        # Run the prioritisation sort
        @from = sort {
            # Optimise the least abundant resource first
            $types{$b->{type}} <=> $types{$a->{type}}
            or
            # Send from the biggest-full planet first
            $b->{stored} <=> $a->{stored}
        } @from;

        # Get the next item to process
        my $source = shift @from;
        my $name   = $source->{name};
        my $type   = $source->{type};
        my $planet = $empire->planet( $source->{planet_id} );

        # Find a ship to use
        my $ship = $planet->cargo_ship or next;

        # Find a planet to send to.
        my $target = List::Util::first {
            $_->{type} eq $type
        } sort {
            # Send to the biggest empty space
            $b->{space} <=> $a->{space}
        } @to or next;

        # How much can we send?
        my $quantity = List::Util::min(
            $source->{stored},
            $target->{space},
            $ship->hold_size,
        ) or next;

        # Push the resource to the target planet
        $self->trace("$name - Pushing $quantity excess $type to $target->{name}");
        $ship->push_items(
            $target->{planet_id},
            $planet->make_items(
                $source->{type} => $quantity,
            ),
        );

        # Update the resource totals
        $target->{space}  -= $quantity;
        $source->{space}  += $quantity;
        $source->{stored} -= $quantity;
        $source->{remaining} = $source->{space} / $source->{hour};
        if ( $source->{remaining} < 4 ) {
            unshift @from, $source;
        }
    }

    return 1;
}

sub trace {
    print scalar(localtime time) . " - MoveResources - " . $_[1] . "\n";
}

1;
