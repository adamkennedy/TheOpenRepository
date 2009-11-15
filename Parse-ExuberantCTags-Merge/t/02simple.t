use 5.006;
use strict;
use warnings;
use Test::More tests => 8;

use Parse::ExuberantCTags::Merge;
chdir('t') if -d 't';
use File::Spec;
use File::Temp ();

my $ptags_sorted     = File::Spec->catfile('data/testtags.sorted');
my $ptags_unsorted   = File::Spec->catfile('data/testtags.unsorted');
my $ptags2_sorted    = File::Spec->catfile('data/testtags2.sorted');
my $ptags2_unsorted  = File::Spec->catfile('data/testtags2.unsorted');
my $ptags_all_sorted = File::Spec->catfile('data/all.sorted');

# test sorting of small sorted file
SCOPE: {
  my $merger = Parse::ExuberantCTags::Merge->new();
  isa_ok($merger, 'Parse::ExuberantCTags::Merge');

  my ($tfh, $tmpfile1) = File::Temp::tempfile(
    "ctagsTestXXXXXXX", UNLINK => 1, TMPDIR => 1,
  );

  $merger->add_file($ptags_sorted, sorted => 1);

  # internals test
  ok(ref($merger->{files}) eq 'ARRAY', 'files attr is an array');
  ok(@{$merger->{files}} == 1, 'files attr has an entry');
    
  $merger->write($tmpfile1);
  is( slurp($tmpfile1), prepend_sorted_tag(slurp($ptags_sorted)), "files are equal" );
}

# test sorting of small sorted file, but mark it as unsorted
SCOPE: {
  my $merger = Parse::ExuberantCTags::Merge->new();
  my ($tfh, $tmpfile1) = File::Temp::tempfile(
    "ctagsTestXXXXXXX", UNLINK => 1, TMPDIR => 1,
  );

  $merger->add_file($ptags_sorted, sorted => 0);

  $merger->write($tmpfile1);
  is( slurp($tmpfile1), prepend_sorted_tag(slurp($ptags_sorted)), "files are equal" );
}

# test sorting of small unsorted file
SCOPE: {
  my $merger = Parse::ExuberantCTags::Merge->new();
  my ($tfh, $tmpfile1) = File::Temp::tempfile(
    "ctagsTestXXXXXXX", UNLINK => 1, TMPDIR => 1,
  );

  $merger->add_file($ptags_unsorted, sorted => 0);

  $merger->write($tmpfile1);
  is( slurp($tmpfile1), prepend_sorted_tag(slurp($ptags_sorted)), "files are equal" );
}

# test sorting of two small sorted files
SCOPE: {
  my $merger = Parse::ExuberantCTags::Merge->new();
  my ($tfh, $tmpfile1) = File::Temp::tempfile(
    "ctagsTestXXXXXXX", UNLINK => 1, TMPDIR => 1,
  );

  $merger->add_file($ptags_sorted, sorted => 1);
  $merger->add_file($ptags2_sorted, sorted => 1);

  $merger->write($tmpfile1);
  is( slurp($tmpfile1), prepend_sorted_tag(slurp($ptags_all_sorted)), "files are equal" );
}

# test sorting of two small unsorted files
SCOPE: {
  my $merger = Parse::ExuberantCTags::Merge->new();
  my ($tfh, $tmpfile1) = File::Temp::tempfile(
    "ctagsTestXXXXXXX", UNLINK => 1, TMPDIR => 1,
  );

  $merger->add_file($ptags_unsorted, sorted => 0);
  $merger->add_file($ptags2_unsorted, sorted => 0);

  $merger->write($tmpfile1);
  is( slurp($tmpfile1), prepend_sorted_tag(slurp($ptags_all_sorted)), "files are equal" );
}



sub slurp {
  my $f1 = shift;
  open my $fh1, '<', $f1 or die "Can't open $f1 for reading: $!";
  local $/ = undef;
  return <$fh1>;
}

sub prepend_sorted_tag {
  my $string = shift;
  my $sorted = shift;
  $sorted = 1 if not defined $sorted;

  return "!_TAG_FILE_SORTED	$sorted	  /0=unsorted, 1=sorted/\n"
         . $string;
}
