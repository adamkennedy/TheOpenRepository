
package App::FQStat::Scanner;
# App::FQStat is (c) 2007-2008-2008 Steffen Mueller
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;
use Time::HiRes qw/sleep/;
use App::FQStat::Debug;

# run qstat
sub run_qstat {
  warnenter if ::DEBUG;
  my $forced = shift;
  lock($::ScannerStartRun);

  if (not defined $::ScannerThread) {
    warnline "Creating new (initial?) scanner thread" if ::DEBUG;
    $::ScannerThread = threads->new(\&App::FQStat::Scanner::scanner_thread);
  }
  elsif ($::ScannerThread->is_joinable()) {
    warnline "Joining scanner thread" if ::DEBUG;
    my $return = $::ScannerThread->join();
    ($::Records, $::NoActiveNodes) = @$return;
    { lock($::RecordsChanged); $::RecordsChanged = 1; }
    warnline "Joined scanner thread. Creating new scanner thread" if ::DEBUG;
    $::ScannerThread = threads->new(\&App::FQStat::Scanner::scanner_thread);
  }
  elsif (!$::ScannerThread->is_running()) {
    warnline "scanner thread not running. Creating new scanner thread" if ::DEBUG;
    undef $::ScannerThread;
    $::ScannerThread = threads->new(\&App::FQStat::Scanner::scanner_thread);
  }
  elsif ($forced) {
    warnline "scanner thread running. Force in effect, setting StartRun" if ::DEBUG;
    $::ScannerStartRun = 1;
  }
}

sub scanner_thread {
  warnenter if ::DEBUG;
  {
    lock($::ScannerStartRun);
    $::ScannerStartRun = 0;
  }

  my @lines;
  my @args;
  {
    lock($::User);
    push @args, '-u', ( (defined($::User) && $::User ne '') ? $::User : '*');
  }

  my $timebefore = time();
  my $qstat = App::FQStat::Config::get("qstatcmd");
  my $output = App::FQStat::System::run_capture($qstat, @args);
  if (not defined $output) {
    die "Running 'qstat' failed!";
  }
  my $duration = time()-$timebefore;

  # Update the update interval according to the time it takes
  {
    lock($::Interval);
    if ($duration >= $::Interval) {
      $::Interval = ($duration > $::Interval*1.8 ? $duration+1.0 : $::Interval*1.8);
    }
    elsif ($duration < $::Interval and $duration > $::UserInterval) {
      $::Interval = ($::Interval/1.1 > $::UserInterval ? $::Interval/1.1 : $::UserInterval);
    }
  }

  @lines = split /\n/, $output;
  shift @lines;
  shift @lines;

  my $noActiveNodes = 0;
  foreach my $line (@lines) {
    $line =~ s/^\s+//;
    my $rec = [split /\s+/, $line];
    $rec->[7] = '' if not $rec->[7] =~ /\D/;
    my @date = split /\//, $rec->[5];
    @date = @date[1, 0, 2];
    my @jobdesc;
    @jobdesc = (
      $rec->[0],        # F_id
      $rec->[1],        # F_prio
      $rec->[2],        # F_name
      $rec->[3],        # F_user
      $rec->[4],        # F_status
      join('.', @date), # F_date
      $rec->[6],        # F_time
      $rec->[7],        # F_queue
    );
    $noActiveNodes++ if $rec->[4] =~ /^\s*r\s*$/;
    $line = \@jobdesc;
  }

  reverse_records(\@lines) if $::RecordsReversed; # retain state of reversal

  sort_current(\@lines);

  lock($::DisplayOffset);
  lock(@::Termsize);
  my $limit = @lines - $::Termsize[1]+4;
  if ($::DisplayOffset and $::DisplayOffset > $limit) {
    $::DisplayOffset = $limit;
  }

  sleep 0.1; # Note to self: fractional sleep without HiRes => CPU=100%
  warnline "End of scanner_thread" if ::DEBUG;
  return [\@lines, $noActiveNodes];
}






# sorts the qstat output by $::SortField
sub sort_current {
  warnenter if ::DEBUG;
  my $lines = shift;
  my $sortfield;
  {
    lock($::SortField);
    if (not defined $::SortField or $::SortField eq '' or not exists $::Columns{$::SortField}) {
      warnline "Nothing to sort" if ::DEBUG;
      return;
    }
    $sortfield = $::SortField;
  }
  my $key = $sortfield;
  my $key_index = ::RECORD_KEY_CONSTANT()->{$key};
  
  my $order;
  $order = $::Columns{$sortfield}{order} unless $sortfield eq 'status';
  $order = 'status' if $sortfield eq 'status';

  warnline "Sorting: key=$key order=$order" if ::DEBUG;

  return if not defined $order;

  my $time = time(); # for debugging / profiling

  if ($order eq 'status') {
    
    @$lines = 
          map { $_->[0] }
          sort { $a->[1] <=> $b->[1] }
          map {
            my $s = $_->[::F_status];
            if    ($s =~ /E/) { $s = 0 }
            elsif ($s =~ /r/) { $s = 1 }
            elsif ($s =~ /t/) { $s = 2 }
            elsif ($s =~ /w/) { $s = 3 }
            else  { $s = 4 }
            [$_, $s]
          }
          @$lines;
  }
  elsif ($order eq 'time') {
    ::debug "Sorting by time";
    @$lines =
          map { $_->[0] }
          sort { $a->[1] <=> $b->[1] or $a->[2] <=> $b->[2] or $a->[3] <=> $b->[3] }
          map { [$_, split(/:/, $_->[$key_index])] }
          @$lines;
  }
  elsif ($order eq 'date') {
    ::debug "Sorting by date";
    @$lines =
          map { $_->[0] }
          sort { $b->[1] <=> $a->[1] or $b->[2] <=> $a->[2] or $b->[3] <=> $a->[3] }
          map { [$_, split(/\./, $_->[$key_index])] }
          @$lines;
  }
  elsif ($order eq 'num') {
    ::debug "Sorting numerically";
    @$lines =
          sort { $a->[$key_index] <=> $b->[$key_index] }
          @$lines;
  }
  elsif ($order eq 'num_highlow') {
    ::debug "Sorting numerically high to low";
    @$lines =
          sort { $b->[$key_index] <=> $a->[$key_index] }
          @$lines;
  }
  else { # default to alpha
    ::debug "Sorting alphabetically";
    @$lines =
          sort { $a->[$key_index] cmp $b->[$key_index] }
          @$lines;
  }

  {
    lock($::RecordsReversed);
    lock($::RecordsChanged);
    reverse_records($::Records) if $::RecordsReversed;
    $::RecordsChanged = 1 if $::RecordsReversed;
  }

  if (::DEBUG()) {
    my $diff = time()-$time;
    ::debug "Sorting took $diff seconds.";
  }
}

# reverse the current set of records
sub reverse_records {
  warnenter if ::DEBUG;
  my $lines = shift;
  @$lines = reverse @$lines;
}


1;


