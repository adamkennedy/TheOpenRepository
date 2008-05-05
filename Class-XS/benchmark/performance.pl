#!/usr/bin/perl
use strict;
use warnings;

package PerlHash;
sub new { my $class = shift; return bless {} =>  $class; }
sub get_attr1 { my $self = shift; return $self->{attr1}; }
sub set_attr1 { my $self = shift; $self->{attr1} = shift; }

package PerlHashD;
sub new { my $class = shift; return bless {} =>  $class; }
sub get_attr1 { my $self = shift; return $self->{attr1}; }
sub set_attr1 { my $self = shift; $self->{attr1} = shift; }
sub DESTROY {}

package PerlArray;
sub new { my $class = shift; return bless [] =>  $class; }
sub get_attr1 { my $self = shift; return $self->[0]; }
sub set_attr1 { my $self = shift; $self->[0] = shift; }

package PerlArrayD;
sub new { my $class = shift; return bless [] =>  $class; }
sub get_attr1 { my $self = shift; return $self->[0]; }
sub set_attr1 { my $self = shift; $self->[0] = shift; }
sub DESTROY {}

package XSHash;
sub new { my $class = shift; return bless {} =>  $class; }
use Class::XSAccessor
  getters => { get_attr1 => 'attr1', },
  setters => { set_attr1 => 'attr1', };

package XSHashD;
sub new { my $class = shift; return bless {} =>  $class; }
sub DESTROY {}
use Class::XSAccessor
  getters => { get_attr1 => 'attr1', },
  setters => { set_attr1 => 'attr1', };

package XSArray;
sub new { my $class = shift; return bless [] =>  $class; }
use Class::XSAccessor::Array
  getters => { get_attr1 => 0, },
  setters => { set_attr1 => 0, };

package XSArrayD;
sub new { my $class = shift; return bless [] =>  $class; }
sub DESTROY {}
use Class::XSAccessor::Array
  getters => { get_attr1 => 0, },
  setters => { set_attr1 => 0, };

package ObjectTiny;
use Object::Tiny qw(attr1);
sub set_attr1 { my $self = shift; $self->{attr1} = shift;}

package ObjectTinyD;
use Object::Tiny qw(attr1);
sub set_attr1 { my $self = shift; $self->{attr1} = shift;}
sub DESTROY {}

package ClassXS;
use Class::XS
  public_attributes => [qw(attr1)];


package main;
use Benchmark qw/cmpthese/;

my $count = 800000;
my $time  = -3;

print "Benchmarking object creation with offset...\n";
our @GSPerlHash;
our @GSPerlHashD;
our @GSPerlArray;
our @GSPerlArrayD;
our @GSXSHash;
our @GSXSHashD;
our @GSXSArray;
our @GSXSArrayD;
our @GSObjectTiny;
our @GSObjectTinyD;
our @GSClassXS;
my @classes = qw(
  PerlHash   PerlHashD
  PerlArray  PerlArrayD
  XSHash     XSHashD
  XSArray    XSArrayD
  ClassXS
);
cmpthese($count, {
  map {$_ => "push \@::GS$_, $_->new();"} (@classes, 'ObjectTiny', 'ObjectTinyD')
},);

print "Benchmarking object destruction with offset...\n";
cmpthese($count, {
  map {$_ => "shift \@::GS$_;"} (@classes, 'ObjectTiny', 'ObjectTinyD')
},);

print "Benchmarking object creation and destruction...\n";
cmpthese($time, {
  map {$_ => "$_->new();"} (@classes, 'ObjectTiny', 'ObjectTinyD')
},);

print "Benchmarking getters...\n";
our $PerlHash    = PerlHash->new();
our $PerlHashD   = PerlHashD->new();
our $PerlArray   = PerlArray->new();
our $PerlArrayD  = PerlArrayD->new();
our $XSHash      = XSHash->new();
our $XSHashD     = XSHashD->new();
our $XSArray     = XSArray->new();
our $XSArrayD    = XSArrayD->new();
our $ObjectTiny  = ObjectTiny->new();
our $ObjectTinyD = ObjectTinyD->new();
our $ClassXS     = ClassXS->new();

cmpthese($time, {
  (map {$_ => "\$::$_->get_attr1();"} @classes),
  ObjectTiny => "\$::ObjectTiny->attr1();",
  ObjectTinyD => "\$::ObjectTinyD->attr1();",
},);

print "Benchmarking setters(undef)...\n";
cmpthese($time, {
  (map {$_ => "\$::$_->set_attr1(undef);"} @classes, 'ObjectTiny', 'ObjectTinyD'),
},);

