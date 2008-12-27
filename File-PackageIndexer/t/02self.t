use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('File::PackageIndexer') };

my $indexer = File::PackageIndexer->new();
isa_ok($indexer, 'File::PackageIndexer');

open my $fh, '<', $INC{"File/PackageIndexer.pm"} or die $!;
my $code = do {local $/=undef; <$fh>};
close $fh;

my $res = $indexer->parse($code);
ok(ref($res) && ref($res) eq 'HASH', "returns hash ref");

#use Data::Dumper; warn Dumper $res;

my $cmp = {
  'File::PackageIndexer' => {
    subs => {
      parse => 1,
      '_lazy_create_pkg' => 1,
    },
  },
};

is_deeply($res, $cmp);

