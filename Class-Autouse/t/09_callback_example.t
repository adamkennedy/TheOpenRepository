#!/usr/bin/env perl

# This is the example from the POD

use strict;
use warnings;
use Test::More tests => 4;

use Class::Autouse sub {
	my ($class) = @_;
	if ($class =~ /(^.*)::Wrapper/) {
		my $wrapped_class = $1;
		eval "package $class; use Class::AutoloadCAN;";
		die $@ if $@;
		no strict 'refs';
		*{$class . '::new' } = sub {
			my $class = shift;
			my $proxy = $wrapped_class->new(@_);
			my $self = bless({proxy => $proxy},$class);
			return $self;
		};
		*{$class . '::CAN' } = sub {
			my ($obj,$method) = @_;
			my $delegate = $wrapped_class->can($method);
			return unless $delegate;
			my $delegator = sub {
				my $self = shift;
				if (ref($self)) {
					return $self->{proxy}->$method(@_);
				}
				else {
					return $wrapped_class->$method(@_);	
				}
			};
			return *{ $class . '::' . $method } = $delegator;	
		};
		
		return 1;
	}
	return;
};


package Foo;

sub new { my $class = shift; bless({@_},$class); }

sub class_method { 123 }

sub instance_method { 
	my ($self,$v) = @_; 
	return $v * $self->some_property
}

sub some_property { shift->{some_property} }


package main;

my $x = Foo::Wrapper->new(some_property => 111);
#print $x->some_property,"\n";
#print $x->instance_method(5),"\n";
#print Foo::Wrapper->class_method,"\n";

isa_ok($x,"Foo::Wrapper");
is($x->some_property,111);
is($x->instance_method(5),555);
is($x->class_method,123);



