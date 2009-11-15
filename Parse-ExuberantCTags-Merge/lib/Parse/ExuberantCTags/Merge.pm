package Parse::ExuberantCTags::Merge;

use 5.006001;
use strict;
use warnings;

our $VERSION = '1.00';
use constant SMALL_DEFAULT       => 2**22;
use constant SUPER_SMALL_DEFAULT => 2**17;

use constant FILENAME            => 0;
use constant SORTED              => 1;

# TODO document these:
use Class::XSAccessor
  constructor => 'new',
  accessors => {
    small_size_threshold       => 'small_size_threshold',
    super_small_size_threshold => 'super_small_size_threshold',
    tempdir                    => 'tempdir',
  };

use Carp ();
use File::Temp ();
use File::Spec ();

sub add_file {
  my $self = shift;
  my $file = shift;
  Carp::croak("Need file argument")
    if not defined $file;
  Carp::croak("Input file '$file' does not exist")
    if not -f $file;
  
  my %opts = @_;
  my $sorted = $opts{sorted};

  $self->{files} ||= [];
  push @{$self->{files}}, [$file, $sorted];
  return();
}


sub write {
  my $self = shift;
  my $outfile = shift;
  Carp::croak("Need output file argument")
    if not defined $outfile;

  # determine temporary directory
  my $tmpdir = $self->tempdir;
  if (not defined $tmpdir or not -d $tmpdir) {
    $tmpdir = File::Spec->tmpdir();
    $self->tempdir($tmpdir);
  }

  my $total_size = 0;
  my $sorted_size = 0;
  my $unsorted_size = 0;
  my @sorted;
  my @unsorted;

  my $files = $self->{files};
  Carp::croak("Need input files")
    if not defined $files or @$files == 0;

  if (@$files == 1 and $files->[0][SORTED]) {
    my $infile = $files->[0][FILENAME];
    open my $fh, '<', $infile
      or die "Opening input file '$infile' for reading failed: $!";
    open my $ofh, '>', $outfile
      or die "Opening output file '$outfile' for writing failed: $!";

    print $ofh "!_TAG_FILE_SORTED	1	  /0=unsorted, 1=sorted/\n";

    local $/ = \1000000;
    while (<$fh>) {
      print $ofh $_;
    }
    return(1);
  }
  
  # calculate the file sizes
  foreach my $file (@$files) {
    my $fname = $file->[FILENAME];
    my $s = -s $fname;
    $total_size += $s;
    if ($file->[SORTED]) {
      $sorted_size += $s;
      push @sorted, $fname;
    }
    else {
      $unsorted_size += $s;
      push @unsorted, $fname;
    }
  }

  # get size thresholds
  my $threshold_super_small = $self->super_small_size_threshold();
  $threshold_super_small = SUPER_SMALL_DEFAULT if not defined $threshold_super_small;
  my $threshold_small = $self->small_size_threshold();
  $threshold_super_small = SMALL_DEFAULT if not defined $threshold_small;

  # storage of temporary files and guard to clean them up on scope exit
  my @tmpfiles;
  require Parse::ExuberantCTags::Merge::SimpleScopeGuard;
  my $guard = Parse::ExuberantCTags::Merge::SimpleScopeGuard->new(files => \@tmpfiles);

  # select sort strategy

  # everything small, sort all in memory regardless
  if ($total_size < $threshold_super_small) {
    open my $ofh, '>', $outfile
      or die "Could not open output file '$outfile' for writing: $!";
    return $self->_memory_sort($ofh, @sorted, @unsorted);
  }
  
  # This must handle the unsorted files
  if (@unsorted) {
    if ($unsorted_size < $threshold_small) {
      # unsorted files are small and will be sorted in memory
      my ($tfh, $tmpfile);
      if (@sorted) {
        ($tfh, $tmpfile) = File::Temp::tempfile(
          "ctagsSortXXXXXX", UNLINK => 0, DIR => $tmpdir
        );
        push @tmpfiles, $tmpfile;
      }
      else { # unsorted only
        open my $tfh, '>', $outfile
          or die "Could not open output file '$outfile' for writing: $!";
      }
      $self->_memory_sort($tfh, @sorted, @unsorted);
      close $tfh;
      if (not @sorted) { # only unsorted data => done!
        return 1;
      }
      push @sorted, $tmpfile;
      $sorted_size += -s $tmpfile;
    }
    elsif ($sorted_size < $threshold_small) {
      # handle everything with Sort::External
      # don't bother with merge-sorting the small sorted files
      open my $ofh, '>', $outfile
        or die "Could not open output file '$outfile' for writing: $!";
      return $self->_external_sort($ofh, @unsorted, @sorted);
    }
    else {
      # both are large. First do an external sort on the unsorted files,
      # then do a merge sort
      my ($tfh, $tmpfile) = File::Temp::tempfile(
        "ctagsSortXXXXXX", UNLINK => 0, DIR => $tmpdir
      );
      push @tmpfiles, $tmpfile;
      $self->_external_sort($tfh, @unsorted);
      close $tfh;
      push @sorted, $tmpfile;
      $sorted_size += -s $tmpfile;
    }
  } # end if there is unsorted data

  # at this point, there should be only sorted files
  # left => merge sort
  
  open my $ofh, '>', $outfile
    or die "Could not open output file '$outfile' for writing: $!";
  return $self->_merge_sort($ofh, @sorted);
}


sub _merge_sort {
  my $self = shift;
  my $ofh = shift;
  my @infiles = @_;

  print $ofh "!_TAG_FILE_SORTED	1	  /0=unsorted, 1=sorted/\n";

  local $/ = "\n";

  require File::MergeSort;
  # use the whole input line as key
  my $sort = File::MergeSort->new(
    \@infiles, sub {$_[0]},
  );

  while (my $line = $sort->next_line) {
    print $ofh $line;
  }

  # TODO using ->dump($filename) would be faster but we need to insert the
  #      tags-sorted line at the beginning... dumping to a file handle?

  return(1);
}



sub _external_sort {
  my $self = shift;
  my $ofh = shift;
  my @infiles = @_;

  print $ofh "!_TAG_FILE_SORTED	1	  /0=unsorted, 1=sorted/\n";

  require Sort::External;
  my $exsort = Sort::External->new(
    mem_threshold => 1024**2 * 32, # todo: configuration
  );

  local $/ = "\n";
  foreach my $infile (@infiles) {
    open my $fh, '<', $infile
      or die "Could not open input file '$infile' for reading: $!";
    my $first_line = <$fh>;
    $exsort->feed($first_line) if $first_line !~ /^!_TAG_FILE_SORTED/;
    while (<$fh>) {
      $exsort->feed($_);
    }
    close $fh;
  }
  $exsort->finish();
  while (defined($_ = $exsort->fetch)) {
    print $ofh $_;
  }

  return(1);
}


sub _memory_sort {
  my $self = shift;
  my $ofh = shift;
  my @infiles = @_;

  local $/ = "\n";
  my @records;
  foreach my $infile (@infiles) {
    open my $fh, '<', $infile
      or die "Could not open input file '$infile' for reading: $!";
    my $first_line = <$fh>;
    push @records, $first_line if $first_line !~ /^!_TAG_FILE_SORTED/;
    push @records, <$fh>;
    close $fh;
  }
  @records = sort @records; # check fast inplace sort
  
  print $ofh "!_TAG_FILE_SORTED	1	  /0=unsorted, 1=sorted/\n";
  print $ofh @records;

  return(1);
}

1;
__END__

=head1 NAME

Parse::ExuberantCTags::Merge - Efficiently merge large exuberant ctags files

=head1 SYNOPSIS

  use Parse::ExuberantCTags::Merge;
  my $merger = Parse::ExuberantCTags::Merge->new();
  $merger->add_file('perltags.old',  sorted => 0);
  $merger->add_file('perltags.new',  sorted => 1);
  $merger->add_file('perltags.new2', sorted => 1);
  # potentially add more files...
  
  # sorting happens only when you call 'write':
  $merger->write('perltags.out');

=head1 DESCRIPTION

This Perl module is intended to merge multiple I<exuberant ctags> files.
The synopsis says all about the interface. In order to be as efficient
as possible, the module uses different sort methods depending on the
input data. In the general case, it will use the L<Sort::External>
module to process the data. There are a few exceptions:

=over 4

=item Pre-sorted input files

If two or more input files contain sorted data, we use the
L<File::MergeSort> module to efficiently sort them before merging
with the remaining data.

=item Small input files

If the total size of the input files is small, we load them into
memory and use Perl's fast sort function. Default limit: C<2^21B == 4MB>.

=item Super-small input files

If the total size of the input files is extremely small, we ignore
whether they're sorted or not and simply resort to Perl's sort.
Default limit: C<2^17B == 128kB>.

=back

The sorting modules are loaded at run-time on demand only.

=head1 TODO

Benchmark.

=head1 SEE ALSO

Exuberant ctags homepage: L<http://ctags.sourceforge.net/>

Wikipedia on ctags: L<http://en.wikipedia.org/wiki/Ctags>

Module that can produce ctags files from Perl code: L<Perl::Tags>

Module that can parse exuberant ctags files: L<Parse::ExuberantCTags>

Sorting modules: L<Sort::External>, L<File::MergeSort>

L<File::PackageIndexer>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
