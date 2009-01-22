#!perl

# Based on the test case created by Kevin Ryde for #42502

# All MyObject instances are held in @instances, only removed by an explicit
# destroy().  This is like Gtk2::Window from perl-gtk2 where top-level
# windows are held by gtk in the "list_toplevels" and stay alive until
# explicitly destroyed.

package MyObject;

use strict;
use warnings;
our @instances;

sub new {
  my ($class) = @_;
  my $self = bless { data => 'this is a myobject' }, $class;
  push @instances, $self;
  return $self;
}

sub destroy {
  my ($self) = @_;
  @instances = grep {$_ != $self} @instances;
}

package main;

use strict;
use warnings;
use Test::Weaken;
use Test::More tests => 3;

is(
    Test::Weaken::poof(
        sub {
            my $obj = MyObject->new;
            $obj->destroy;
            return $obj
         }
    ), 0
);

is(
    Test::Weaken::poof(
        sub { MyObject->new },
        sub {
            my ($obj) = @_;
            $obj->destroy;
        }
    ), 0
);

is(
    Test::Weaken::poof(
        sub { MyObject->new },
        sub { my ($obj) = @_ }
    ), 1
);
