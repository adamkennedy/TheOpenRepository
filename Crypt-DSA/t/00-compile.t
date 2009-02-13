# $Id: 00-compile.t 192 2001-04-21 08:40:01Z btrott $

my $loaded;
BEGIN { print "1..1\n" }
use Crypt::DSA;
$loaded++;
print "ok 1\n";
END { print "not ok 1\n" unless $loaded }
