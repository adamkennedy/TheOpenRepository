#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../inc";
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../Parse-Binary/lib";
use Test::More tests => 4;

$SIG{__DIE__} = sub { use Carp; Carp::confess(@_) };
$SIG{__WARN__} = sub { use Carp; Carp::cluck(@_) };

use_ok('Win32::Exe');
my $parexe = "$FindBin::Bin/par.exe";
my $testexe = "$FindBin::Bin/par2.exe";

open my $fhi, '<', $parexe;
open my $fho, '>', $testexe;
binmode($fhi);
binmode($fho);
while(<$fhi>) {
  print $fho $_;
}
close($fhi);
close($fho);

my $exe = Win32::Exe->new($testexe);
isa_ok($exe, 'Win32::Exe');

my $manifest = $exe->manifest();
isa_ok($manifest, 'Win32::Exe::Resource::Manifest');

my $xml = $manifest->default_manifest;
ok($exe->update( 'manifest' => $xml ). 'update');

1;
