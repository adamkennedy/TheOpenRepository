use 5.010;
use strict;
use warnings;
use Fatal qw(:void open close unlink select);
use English;

our $FH;

sub change {
   my $fix = shift;
   my @files = @_;
   for my $file (@files) {
     open(FH, '<', $file);
     my $text = do {local $RS; <FH> };
     my $backup = $file . ".save";
     rename($file, $backup);
     open(ARGVOUT, '>', $file);
     select(ARGVOUT);
     say STDERR $text;
     print ARGVOUT $fix->(\$text);
     select(STDOUT);
     close(FH);
   }
}

sub fix1 {
    my $text_ref = shift;
    ${$text_ref} =~ s/foo/bar/;
    $text_ref;
}

change(\&fix1, qw(test));
