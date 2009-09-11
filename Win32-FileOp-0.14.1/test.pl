# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Win32::FileOp;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

{
 my $ok=1;
 my $fail = 0;
 my $skip = 0;
 my $test=1;
 sub ok {
    $test++;
    $ok++;
    print ($_[0] ? "ok  $test - $_[0]\n" : "ok  $test\n");
 }

 sub fail {
    $test++;
    $fail++;
    print ($_[0] ? "BAD $test - $_[0]\n" : "BAD $test\n");
 }

 sub skip {
    $test++;
    $skip++;
    print ($_[0] ? "skip $test - $_[0]\n" : "skip $test\n");
 }

 sub res {
    print "Tests: $test, ok: $ok, failed: $fail, skipped: $skip\n";
 }
}

$handle = GetDesktopHandle();
if ($handle) {
    print "The desktop handle is : $handle - ";
    ok;
} else {
    fail;
}

$handle = GetWindowHandle();
if ($handle) {
    print "This console handle is : $handle - ";
    ok;
} else {
    fail;
}

Copy 'Makefile.PL' => 'test_dir\\'
 and (-e 'test_dir\\Makefile.PL')
 and ok
 or fail;

Copy 'FileOp.pm' => 'test_dir\\f.pm'
 and (-e 'test_dir\\f.pm')
 and ok
 or fail;

Move 'test_dir\\f.pm' => 'test_dir\\OpFile.pm'
 and (!-e 'test_dir\\f.pm')
 and (-e 'test_dir\\OpFile.pm')
 and ok
 or fail;

my $ISA_TTY = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));

if ($ISA_TTY) {
	print "You should get a confirmation dialog now, click on YES!\n";
	(CopyConfirm 'Changes' => 'test_dir\\OpFile.pm'
	 and -s('Changes') == -s('test_dir\\OpFile.pm')
	 and ok)
	 or fail;
} else {
	skip("this seems to be an automated build script")
}

Delete 'test_dir'
	and ok
	or fail;
