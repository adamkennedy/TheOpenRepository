#!perl

# Based on the test case created by Kevin Ryde for #42502

# All MyObject instances are held in @INSTANCES, only removed by an explicit
# destroy().  This is like Gtk2::Window from perl-gtk2 where top-level
# windows are held by gtk in the "list_toplevels" and stay alive until
# explicitly destroyed.

package MyObject;

use strict;
use warnings;
our @INSTANCES;

sub new {
    my ($class) = @_;
    my $self = bless { data => ['this is a myobject'] }, $class;
    push @INSTANCES, $self;
    return $self;
}

sub destroy {
    my ($self) = @_;
    return ( @INSTANCES = grep { $_ != $self } @INSTANCES );
}

package main;

use strict;
use warnings;
use Test::Weaken;
use Test::More tests => 2;

use lib 't/lib';
use Test::Weaken::Test;

@INSTANCES = ();
my $result = Test::Weaken::poof(
    sub { MyObject->new },
    sub {
        my ($obj) = @_;
        $obj->destroy;
    }
);
Test::Weaken::Test::is( $result, 0, 'good destructor' );

@INSTANCES = ();
$result = Test::Weaken::poof( sub { return MyObject->new }, sub { } );
Test::Weaken::Test::is( $result, 2, 'no-op destructor' );
