#!perl

use 5.010_000;
use Fatal qw( close waitpid );
use English qw( -no_match_vars );
use IPC::Open2;

my %exclude = map { $_, 1 } qw(
Changes
MANIFEST
META.yml
Makefile.PL
README
bootstrap/bootstrap_header.pl
bootstrap/bootstrap_trailer.pl
etc/perlcriticrc
lib/Parse/Marpa/Raw_Source.pm
lib/Parse/Marpa/header_Raw_Source.pm
lib/Parse/Marpa/trailer_Raw_Source.pm
t/lib/Test/Weaken.pm
);

sub run_critic {
    my $file = shift;
    my @cmd = qw(perlcritic -profile perlcriticrc);
    push @cmd, $file;
    my ($child_out, $child_in);
    say STDERR join(" ", @cmd);
    my $pid = open2($child_out, $child_in, @cmd)
        or croak("IPC::Open2 of perlcritic pipe failed: $ERRNO");
    close $child_in;
    local($RS) = undef;
    my $critic_output = <$child_out>;
    waitpid $pid, 0;
    say STDERR "perlcritic returned $CHILD_ERROR" if $CHILD_ERROR;
    my @newlines = ($critic_output =~ m/\n/xmsg);
    say STDERR 'Output length: ', scalar @newlines;
    return \$critic_output;
}

open my $manifest, '<', '../MANIFEST'
    or croak("open of MANIFEST failed: $ERRNO");
FILE: while (my $file = <$manifest>) {
    chomp $file;
    $file =~ s/\s*[#].*\z//;
    next FILE if $file =~ /.pod\z/xms;
    next FILE if $file =~ /.marpa\z/xms;
    next FILE if $file =~ /\/Makefile\z/xms;
    next FILE if $exclude{$file};
    $file = '../' . $file;
    next FILE if -d $file;
    croak("No such file: $file") unless -f $file;
    say "=== $file ===";
    my $result = run_critic( $file );
    # say ${$result};
}
