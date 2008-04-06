use strict;
use warnings;
use File::Spec;

BEGIN {
  require AutoXS;
#  AutoXS->import(debug => 1);
  require AutoXS::Getter;
  require lib;
  if (-d 'data') {
    lib->import('data');
  }
  elsif (-d File::Spec->catdir('t', 'data')) {
    lib->import(File::Spec->catdir('t', 'data'));
  }
  else {
    die "Could not find Getter test code.";
  }
  require GetterTest;
}

use Test::More tests => GetterTest->get_number_of_tests();

GetterTest->test_matching();

