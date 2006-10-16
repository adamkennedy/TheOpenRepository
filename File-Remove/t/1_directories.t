# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-Remove.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More qw(no_plan); # tests => 2;
BEGIN { use_ok('File::Remove' => qw(remove trash)) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @dirs = ("$0.tmp", map { "$0.tmp/$_" } qw(a a/b c c/d e e/f g));

for my $path (reverse @dirs) {
    if (-e $path) {
	ok rmdir($path),
	  "rmdir: $path";
	ok !-e $path,
	  "!-e: $path";
    }
}

for my $path (@dirs) {
    ok !-e $path,
      "!-e: $path";
    ok mkdir($path),
      "mkdir: $path";
	chmod 0777, $path;
    ok -e $path,
      "-e: $path";
}

for my $path (reverse @dirs) {
    ok -e $path,
      "-e: $path";
    ok rmdir($path),
      "rmdir: $path";
    ok !-e $path,
      "!-e: $path";
}

for my $path (@dirs) {
    ok !-e $path,
      "!-e: $path";
    ok mkdir($path),
      "mkdir: $path";
	chmod 0777, $path;
    ok -e $path,
      "-e: $path";
}

for my $path (reverse @dirs) {
    ok -e $path,
      "-e: $path";
    ok remove(\1, $path),
      "remove \\1: $path";
    ok !-e $path,
      "!-e: $path";
}

for my $path (@dirs) {
    ok !-e $path,
      "!-e: $path";
    ok mkdir($path),
      "mkdir: $path";
	chmod 0777, $path;
    ok -e $path,
      "-e: $path";
}

for my $path (reverse @dirs) {
    ok -e $path,
      "-e: $path";
    ok remove($path),
      "remove: $path";
    ok !-e $path,
      "!-e: $path";
}

for my $path (reverse @dirs) {
    ok !-e $path,
      "-e: $path";
    if (-e _) {
	ok rmdir($path),
	  "rmdir: $path";
	ok !-e $path,
	  "!-e: $path";
    }
}

SKIP: {
    if ($^O eq 'darwin') {
        eval 'use Mac::Glue ();';
        skip "Undelete support requires Mac::Glue", 0 if length $@;
	eval 'use Mac::Glue::Finder ();';
        skip "Undelete support requires Mac::Glue::Finder", 0 if length $@;
    } elsif ($^O eq 'cygwin' || $^O =~ /^MSWin/) {
        eval 'use Win32::FileOp::Recycle;';
        skip "Undelete support requires Win32::FileOp::Recycle", 0 if length $@;
    } else {
        skip "Undelete support not available by default", 0;
    }
    
    for my $path (@dirs) {
	ok !-e $path,
	  "!-e: $path";
	ok mkdir($path),
	  "mkdir: $path";
	chmod 0777, $path;
	ok -e $path,
	  "-e: $path";
    }

    for my $path (reverse @dirs) {
	ok -e $path,
	  "-e: $path";
      ok eval { trash($path) },
        "trash: $path";
      is $@, '',
        "trash: \$@";
      ok !-e $path,
        "!-e: $path";
    }

    for my $path (reverse @dirs) {
	ok !-e $path,
	  "-e: $path";
	if (-e _) {
	    ok rmdir($path),
	      "rmdir: $path";
	    ok !-e $path,
	      "!-e: $path";
	}
    }

    for my $path (@dirs) {
	ok !-e $path,
	  "!-e: $path";
	ok mkdir($path),
	  "mkdir: $path";
	chmod 0777, $path;
	ok -e $path,
	  "-e: $path";
    }

    for my $path (reverse @dirs) {
	ok -e $path,
	  "-e: $path";
	ok remove($path),
	  "remove: $path";
	ok !-e $path,
	  "!-e: $path";
    }

    for my $path (reverse @dirs) {
	ok !-e $path,
	  "-e: $path";
	if (-e _) {
	    ok rmdir($path),
	      "rmdir: $path";
	    ok !-e $path,
	      "!-e: $path";
	}
    }

    for my $path (@dirs) {
	ok !-e $path,
	  "!-e: $path";
	ok mkdir($path),
	  "mkdir: $path";
	chmod 0777, $path;
	ok -e $path,
	  "-e: $path";
    }

    for my $path (reverse @dirs) {
	ok -e $path,
	  "-e: $path";
	ok eval { trash({ 'rmdir' => sub { 1 }, 'unlink' => sub { 1 } }, $path) },
	  "trash: $path";
	ok -e $path,
	  "-e: $path";
	ok rmdir($path),
	  "rmdir: $path";
	ok !-e $path,
	  "!-e: $path";
    }

    UNDELETE: 1;
}

1;
