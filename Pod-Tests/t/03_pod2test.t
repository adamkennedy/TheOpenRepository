#!/usr/bin/perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
	my($class, $var) = @_;
	return bless { var => $var }, $class;
}

sub PRINT  {
	my($self) = shift;
	${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 't/02_tests.t';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 92 t/02_tests.t
ok(2+2 == 4);
is( __LINE__, 93 );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 104 t/02_tests.t

my $foo = 0;  is( __LINE__, 105 );
ok( !$foo,      'foo is false' );
ok( $foo == 0,  'foo is zero'  );


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 181 t/02_tests.t
  use File::Spec;
  is( $Original_File, File::Spec->catfile(qw(t 02_tests.t)) );


  is( __LINE__, 185, 'line in =for testing' );



  is( __LINE__, 189, 'line in =begin/end testing' );


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 114 t/02_tests.t

  # This is an example.
  2+2 == 4;
  5+5 == 10;

;

  }
};
is($@, '', "example from line 114");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 124 t/02_tests.t
  sub mygrep (&@) { }


  mygrep { $_ eq 'bar' } @stuff
;

  }
};
is($@, '', "example from line 124");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 132 t/02_tests.t

  my $result = 2 + 2;




;

  }
};
is($@, '', "example from line 132");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 132 t/02_tests.t

  my $result = 2 + 2;




  ok( $result == 4,         'addition works' );
  is( __LINE__, 139 );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 144 t/02_tests.t

  local $^W = 1;
  print "Hello, world!\n";
  print STDERR  "Beware the Ides of March!\n";
  warn "Really, we mean it\n";




;

  }
};
is($@, '', "example from line 144");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 144 t/02_tests.t

  local $^W = 1;
  print "Hello, world!\n";
  print STDERR  "Beware the Ides of March!\n";
  warn "Really, we mean it\n";




  is( $_STDERR_, <<OUT,       '$_STDERR_' );
Beware the Ides of March!
Really, we mean it
OUT
  is( $_STDOUT_, "Hello, world!\n",                   '$_STDOUT_' );
  is( __LINE__, 158 );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 161 t/02_tests.t

  1 + 1 == 2;

;

  }
};
is($@, '', "example from line 161");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 169 t/02_tests.t

  print "Hello again\n";
  print STDERR "Beware!\n";

;

  }
};
is($@, '', "example from line 169");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 194 t/02_tests.t

  BEGIN{binmode STDOUT};

;

  }
};
is($@, '', "example from line 194");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

