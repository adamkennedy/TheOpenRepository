#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
	use_ok( 'PITA::POE::SupportServer' ); # 1
        use_ok( 'PITA::Test::Image::Qemu' ); # 2
};


my $image = PITA::Test::Image::Qemu->filename;

ok( -f $image, 'Image file exists' ); # 3

my $server = PITA::POE::SupportServer->new(
    execute => [
        $image,
    ],
    http_mirrors => {
        '/cpan' => '.',
    },
    http_local_addr => '127.0.0.1',
    http_local_port => 8080,
);

ok( 1, 'Server created' ); # 4

$server->prepare() or die $server->{errstr};

ok( 1, 'Server prepared' ); # 5

$server->run() or die $server->{errstr};

ok( 1, 'Server ran' ); # 6

exit(0);
