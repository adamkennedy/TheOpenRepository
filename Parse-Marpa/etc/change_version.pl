use 5.010;
use strict;
use warnings;
use Fatal qw(:void open close unlink select);
use English;

my @test_files = qw(
./bootstrap/self.marpa
./example/null_value.marpa
./example/equation.marpa
./example/synopsis.pl
./lib/Parse/Marpa.pm
./lib/Parse/Marpa/Doc/Internals.pod
./lib/Parse/Marpa/Doc/MDL.pod
./lib/Parse/Marpa/MDL.pm
./t/ah_s.t
./t/cycle.t
./t/cycle2.t
./t/minus_s.t
./t/randal.t
./author.t/MDL_displays.marpa
./author.t/minimal.marpa
./author.t/misc.pl
);

our $FH;

croak("usage: $0: old_version new_version") unless scalar @ARGV == 2;

my ($old, $new) = @ARGV;

say STDERR "$old $new";

sub version {
   my $version = shift;
   my ($major, $minor) = ($version =~ m/^ ([0-9]+) [.] ([0-9_.]+) $/x);
   if (not defined $minor) {
       croak("Bad format in version number: $version");
   }
   my $subminor;
   if (length $minor == 3) {
       $subminor = '000';
   }  elsif ($minor =~ /[._]/) {
       ($minor, $subminor) = ($minor =~ /^ ([0-9]{3}) [._] ([0-9]{3}) $/x);
       croak("Bad format in minor version number: $version")
          unless defined $subminor;
   } else {
       ($minor, $subminor) = ($minor =~ /^ ([0-9]{3}) ([0-9]{3}) $/x);
   }
   my $developer = $minor % 2;
   my $cpan_minor_separator = $developer ? '_' : '.';
   my $literal_minor_separator = $developer ? '_' : '';
   my $cpan = $major . '.' . $minor . $cpan_minor_separator . $subminor;
   my $literal = $major . '.' . $minor . $literal_minor_separator. $subminor;
   my $numeric = $major . '.' . $minor . $subminor;
   my $marpa = join('.', $major+0, $minor+0, $subminor+0);
   return ($cpan, $literal, $numeric, $marpa);
}

my ($old_cpan, $old_literal, $old_numeric, $old_marpa) = version($old);
my ($new_cpan, $new_literal, $new_numeric, $new_marpa) = version($new);

croak("$old >= $new") if $old_numeric+0 >= $new_numeric+0;

say "($old_cpan, $old_literal, $old_numeric, $old_marpa) = version($old)";
say "($new_cpan, $new_literal, $new_numeric, $new_marpa) = version($new)";

sub change {
   my $fix = shift;
   my @files = @_;
   for my $file (@files) {
     open(FH, '<', $file);
     my $text = do {local $RS; <FH> };
     my $backup = "save/$file";
     rename($file, $backup);
     open(ARGVOUT, '>', $file);
     select(ARGVOUT);
     print ARGVOUT ${$fix->(\$text)};
     select(STDOUT);
     close(FH);
   }
}

sub fix_META_yml {
    my $text_ref = shift;
    ${$text_ref} =~ s/(version:\s*)$old_cpan/$1$new_cpan/g;
    $text_ref;
}

sub fix_Marpa_pm {
    my $text_ref = shift;
    ${$text_ref} =~ s/(our\s+\$VERSION\s*=\s*')$old_literal';/$1$new_literal';/;
    ${$text_ref} =~ s/(version\s+is\s+)$old_marpa/$1$new_marpa/;
    $text_ref;
}

sub fix_bootstrap_pl {
    my $text_ref = shift;
    ${$text_ref} =~ s/(\$new_version\s*=\s*')$old_numeric';/$1$new_numeric';/;
    $text_ref;
}

sub fix_test_files {
    my $text_ref = shift;
    ${$text_ref} =~ s/(version\s+is\s+)$old_marpa/$1$new_marpa/g;
    $text_ref;
}

change(\&fix_META_yml, 'META.yml');
change(\&fix_Marpa_pm, 'lib/Parse/Marpa.pm');
change(\&fix_bootstrap_pl, 'bootstrap/bootstrap.pl');
change(\&fix_test_files, @test_files);

