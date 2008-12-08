#!/usr/bin/perl
use lib qw( ./lib );
use Macropod::Parser;
use Macropod::Cache;
use Data::Dumper;

$Data::Dumper::Maxdepth = 3;


my $p = Macropod::Parser->new();
$p->init_cache;

while ( my $file = <STDIN> ) {
	chomp $file;
#my $cached =  $p->have_cached( file=>$file );
	warn $file, $/;
	my $doc = $p->parse_file( $file );
	next unless $doc;
	warn $doc->title,$/;

	$p->process($doc);
	#warn $doc->yaml;
	#print Dumper $doc;

}




