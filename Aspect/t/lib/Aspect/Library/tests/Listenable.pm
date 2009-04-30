package Aspect::Library::tests::Listenable;

use strict;
use warnings;
use Carp;
use Test::More;
use Aspect;
use Aspect::Library::Listenable;
use Test::Exception;

use base qw(Test::Class);

my $Demo_Class = 'Aspect_Library_Listenable_Point';

# setup the listenable relationship type --------------------------------------

aspect Listenable =>
	(Erase => call "${Demo_Class}::set_erased");

aspect Listenable =>
	(Color => call "${Demo_Class}::set_color", color => 'get_color');

# test methods ----------------------------------------------------------------

sub erase_event: Test(2) {
	my $self = shift;
	my $has_been_called = 0;
	my $point = $Demo_Class->new;
	add_listener $point, Erase => my $listener = sub { $has_been_called = 1 };
	$point->set_erased;
	ok $point->get_erased, 'has been erased';
	ok $has_been_called, 'has been called';
	remove_listener $point, Erase => $listener;
}

sub erase_event_2_listeners: Test(2) {
	my $self = shift;
	my $has_been_called1 = 0;
	my $has_been_called2 = 0;
	my $point = $Demo_Class->new;
	add_listener $point, Erase => my $listener1 = sub { $has_been_called1 = 1 };
	add_listener $point, Erase => my $listener2 = sub { $has_been_called2 = 1 };
	$point->set_erased;
	ok $has_been_called1, 'listener 1';
	ok $has_been_called2, 'listener 2';
	remove_listener $point, Erase => $listener1;
	remove_listener $point, Erase => $listener2;
}

sub erase_event_2_listenables: Test(4) {
	my $self = shift;
	my $has_been_called1 = 0;
	my $has_been_called2 = 0;
	my $point1 = $Demo_Class->new;
	my $point2 = $Demo_Class->new;
	add_listener $point1, Erase => my $listener1 = sub { $has_been_called1 = 1 };
	add_listener $point2, Erase => my $listener2 = sub { $has_been_called2 = 1 };
	$point2->set_erased;
	ok !$point1->get_erased, 'point 1';
	ok $point2->get_erased, 'point 2';
	ok !$has_been_called1, 'listener 1';
	ok $has_been_called2, 'listener 2';
	remove_listener $point1, Erase => $listener1;
	remove_listener $point2, Erase => $listener2;
}

sub remove_a_listener: Test(2) {
	my $self = shift;
	my $has_been_called1 = 0;
	my $has_been_called2 = 0;
	my $point = $Demo_Class->new;
	add_listener $point, Erase => my $listener1 = sub { $has_been_called1 = 1 };
	add_listener $point, Erase => my $listener2 = sub { $has_been_called2 = 1 };
	remove_listener $point, Erase => $listener1;
	$point->set_erased;
	ok !$has_been_called1, 'listener 1';
	ok $has_been_called2, 'listener 2';
	remove_listener $point, Erase => $listener2;
}

sub color_event: Test(8) {
	my $self = shift;
	my $event = 0;
	my $point = $Demo_Class->new;
	add_listener $point, Color => my $listener = sub { $event = shift };
	$point->set_color('red');
	is $point->get_color, 'red', 'point color';
	ok $event, 'event fired';
	is ref $event, 'Aspect::Library::Listenable::Event', 'event class';
	is $event->name, 'Color', 'name';
	is $event->source, $point, 'source';
	is $event->color, 'red', 'color';
	is $event->old_color, 'blue', 'old_color';
	is_deeply $event->params, ['red'], 'params';
	remove_listener $point, Color => $listener;
}

sub color_event_no_change: Test {
	my $self = shift;
	my $hasnt_been_called = 1;
	my $point = $Demo_Class->new;
	add_listener $point, Color =>
		my $listener = sub { $hasnt_been_called = 0 };
	$point->set_color('blue');
	ok $hasnt_been_called;
	remove_listener $point, Color => $listener;
}

sub die_on_none_hash_based_listenable: Test {
	my $self = shift;
	my $listenable = bless [], 'SomePackage';
	throws_ok
		{ add_listener $listenable, Event => sub {} }
		qr/not a hash based object/;
}

sub object_listener: Test(2) {
	my $self = shift;
	my $point = $Demo_Class->new;
	add_listener $point, Erase => [do_call =>
		my $listener = Aspect_Library_Listenable_Listener->new,
		[qw(source)],
	];
	ok !$listener->has_been_called, 'before erased';
	$point->set_erased;
	is $listener->has_been_called, $point, 'after erased';
	remove_listener $point, Erase => $listener;
}

# test helper classes ---------------------------------------------------------

package Aspect_Library_Listenable_Point;
sub new        { bless {color => 'blue', erased => 0}, shift }
sub get_erased { shift->{erased} }
sub set_erased { shift->{erased} = 1 }
sub get_color  { shift->{color} }
sub set_color  { shift->{color} = pop }


package Aspect_Library_Listenable_Listener;
sub new             { bless {has_been_called => 0}, shift }
sub do_call         { shift->{has_been_called} = pop }
sub has_been_called { shift->{has_been_called} }


1;
