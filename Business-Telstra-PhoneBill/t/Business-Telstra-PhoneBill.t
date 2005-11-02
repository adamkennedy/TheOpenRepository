# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-Telstra-PhoneBill.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
use FindBin qw();


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Business::Telstra::PhoneBill;

my $csv  = $FindBin::Bin.'/test.csv';
my $bill = Business::Telstra::PhoneBill->new(-file => $csv);
ok(1, 'include'); # If we made it this far, we're ok.
ok(defined $bill && ref $bill eq 'Business::Telstra::PhoneBill', 'new works');
ok($bill->filetype eq 'application/octet-stream','check filetype (csv)');

my $zip  = $FindBin::Bin.'/test.zip';
$bill->file($zip);
ok($bill->filetype eq 'application/zip','check filetype (zip)');

my $memref = $bill->entries();
ok(scalar(@$memref) == 5,'parsing and entries()');
ok($memref->[1]->from_number() eq '5235 234 125', 'from_number()');
