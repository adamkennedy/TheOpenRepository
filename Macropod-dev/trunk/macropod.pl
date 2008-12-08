#!/usr/bin/perl
use strict;
use warnings;
use lib qw( ./lib );

use Macropod::Parser;
use Data::Dumper;
#$Data::Dumper::Maxdepth =2;
my $m = Macropod::Parser->new();
my $doc = $m->parse(  $ARGV[0] );
$doc ||= $m->parse_file( $ARGV[0] );
$doc->source( undef );
$doc->ppi( undef);

print Dumper $doc;
print 'Done';
#$m->render;
