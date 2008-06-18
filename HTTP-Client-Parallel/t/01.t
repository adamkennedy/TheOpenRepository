use strict;
use warnings;
use HTTP::Client::Parallel qw(mirror get);
use Data::Dumper;
use FindBin qw($Bin);

my $mirror_dir = "$Bin/test-download";

my $client = HTTP::Client::Parallel->new();

# get
if( 0 ) {
my $responses = $client->get( 'http://www.google.com',
                          'http://www.yapc.org',
                          'http://www.yahoo.com',
                        );

#warn Dumper( $responses );
}

# mirror
my $responses = $client->mirror( 'http://www.google.com' => "$mirror_dir/google.html");

$responses = mirror( 'http://www.google.com' => "$mirror_dir/google.html");

warn Dumper( $responses );
