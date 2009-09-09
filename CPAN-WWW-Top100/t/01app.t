#!C:\strawberry\perl\bin\perl.exe -w
use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'CPAN::WWW::Top100' }

ok( request('/')->is_success, 'Request should succeed' );
