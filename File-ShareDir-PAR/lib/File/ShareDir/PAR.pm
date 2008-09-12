package File::ShareDir::PAR;

=pod

=head1 NAME

File::ShareDir::PAR - File::ShareDir with PAR support

=head1 SYNOPSIS

  use File::SharedDir::PAR ':ALL';
  # exact same interface as the normal File::ShareDir:
  
  # Where are distribution-level shared data files kept
  $dir = dist_dir('File-ShareDir');
  
  # Where are module-level shared data files kept
  $dir = module_dir('File::ShareDir');
  
  # Find a specific file in our dist/module shared dir
  $file = dist_file(  'File-ShareDir',  'file/name.txt');
  $file = module_file('File::ShareDir', 'file/name.txt');
  
  # Like module_file, but search up the inheritance tree
  $file = class_file( 'Foo::Bar', 'file/name.txt' );

=head1 WARNING

This module contains I<highly experimental> code. If you want
to load modules from C<.par> files using PAR
and then access their shared directory using File::ShareDir,
you probably have no choice but to use it. But beware,
here be dragons.

=head1 DESCRIPTION

C<File::ShareDir::PAR> provides the same functionality
as L<File::ShareDir> but tries hard to be compatible with
L<PAR> packaged applications.

The problem is, that the concept of having a distribution or
module specific I<share> directory becomes a little hazy
when you're loading everything from a single file.
L<PAR> uses an C<@INC> hook to intercept any attempt to load
a module. L<File::ShareDir> uses the directory structure that
is typically found in the directories that are listed in C<@INC>
for storing the shared data. In a C<PAR> enviroment, this is
not necessarily possible.

When you call one of the functions that this module provides,
it will take care to search in any of the currently loaded
C<.par> files before scanning C<@INC>. This is the same
order of preference you get for loading modules when PAR is
in effect. If the path or file you are asking for is found
in one of the loaded C<.par> files, that containing
C<.par> file is extracted and the path returned will
point to the extracted copy on disk.

Depending on how you're using PAR, the files that are extracted
this way are either cleaned up after program termination
or cached for further executions. Either way, you're safe if
you use the shared data as read-only data. If you write to it,
your changes may be lost after the program ends.

For any further usage information, including the list of exportable
functions, please refer to the documentation of L<File::ShareDir>.

=cut

use 5.005;
use strict;
use base 'Exporter';
use Carp             'croak';
use File::ShareDir   ();
use File::Spec       ();
use Params::Util     '_CLASS';
use Class::Inspector ();
use Config           ();
use File::Path       ();

use vars qw{$VERSION @EXPORT_OK %EXPORT_TAGS %CLEANUP_DIRS};
BEGIN {
  $VERSION     = '0.01';
  @EXPORT_OK   = qw{dist_dir dist_file module_dir module_file class_file};
  %EXPORT_TAGS = (
    ALL => [ @EXPORT_OK ],
  );
}

use constant IS_MACOS => !!($^O eq 'MacOS');

# cleanup temporary extraction dirs.
# should be handled by PAR, but since we're
# abusing it to extract full .par's to inc/,
# we'd better take care!
END {
  foreach my $directory (keys %CLEANUP_DIRS) {
    File::Path::rmtree($directory) if -d $directory;
  }
}

# This isn't nice: Breaking PAR encapsulation.
# finds the specified file in the loaded .par's
# and returns the zip member and zip handle on
# success
{
  my $ver          = $Config::Config{version};
  my $arch         = $Config::Config{archname};
  sub _par_find_zip_member {
    my $file         = shift;

    require PAR;

    $file =~ s/\/+$//;

    my @files = (
      $file, "lib/$file", "arch/$file",
      "$arch/$file", "$ver/$file", "$ver/$arch/$file"
    );
    @files = map {($_, "$_/")} @files;
    #use Data::Dumper; warn Dumper \@files;
    foreach my $zip (@PAR::LibCache) {
        my $member = PAR::_first_member($zip, @files) or next;
        return($member, $zip);
    }

    return;
  }
}

sub _par_in_use {
  return() unless exists $INC{"PAR.pm"};
  return() unless @PAR::LibCache;
  return 1;
}

{
  my %extracted_already;
  sub _search_and_unpar {
    my $zippath = shift;
    my ($member, $zip) = _par_find_zip_member($zippath);
    if ($member) {
      if (exists $extracted_already{$zip}) {
        my $inc = $extracted_already{$zip};
        return $inc;
      }
      else {
        # watch out: breaking PAR encapsulation
        my $inc = PAR::_extract_inc($zip, 'force');
        $CLEANUP_DIRS{$inc} = 1;
        $extracted_already{$zip} = $inc;
        return $inc;
      }
    }
    return();
  }
}


#####################################################################
# Interface Functions

sub dist_dir {
  my @args = @_;
  my $dist = File::ShareDir::_DIST(shift);

  # Create the subpath
  my $zippath = join (
    '/',
    'auto', split( /-/, $dist )
  );

  _search_and_unpar($zippath) if _par_in_use();

  # hide from croak  
  @_ = @args;
  goto &File::ShareDir::dist_dir;
}


sub module_dir {
  my @args = @_;
  my $module = File::ShareDir::_MODULE(shift);

  my $short  = Class::Inspector->filename($module);
  if (_par_in_use()) {
    my $inc = _search_and_unpar($short);
    if (defined $inc) {
      # Holy shit, I'm so evil. Somebody will find out I did this.
      $INC{$short} = Class::Inspector->resolved_filename($module);
    }
  }

  # hide from croak  
  @_ = @args;
  goto &File::ShareDir::module_dir;
}


sub dist_file {
  my @args = @_;
  my $dist = File::ShareDir::_DIST(shift);
  my $file = File::ShareDir::_FILE(shift);

  # Create the subpath
  my $zippath = join (
    '/',
    'auto', split( /-/, $dist ), File::Spec->splitdir($file)
  );

  _search_and_unpar($zippath) if _par_in_use();

  # hide from croak  
  @_ = @args;
  goto &File::ShareDir::dist_file;
}


sub module_file {
  my @args = @_;
  my $module = File::ShareDir::_MODULE($_[0]);
  my $dir    = module_dir($module);
  @_ = @args;
  goto &File::ShareDir::module_file;
}


sub class_file {
  my @args = @_;
  my $module = File::ShareDir::_MODULE(shift);

  # This had to be copied from File::ShareDir.
  ### BEGIN VERBATIM COPY ###
        # Get the super path ( not including UNIVERSAL )
        # Rather than using Class::ISA, we'll use an inlined version
        # that implements the same basic algorithm.
        my @path  = ();
        my @queue = ( $module );
        my %seen  = ( $module => 1 );
        while ( my $cl = shift @queue ) {
                push @path, $cl;
                no strict 'refs';
                unshift @queue, grep { ! $seen{$_}++ }
                        map { s/^::/main::/; s/\'/::/g; $_ }
                        ( @{"${cl}::ISA"} );
        }
  ### END VERBATIM COPY ###

  foreach my $class ( @path ) {
    eval { module_dir($class); };
  }

  # hide from croak
  @_ = @args;
  goto &File::ShareDir::class_file;
}



1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-ShareDir-PAR>

For other issues, contact the PAR mailing list: E<lt>par@perl.orgE<gt>

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

The code was adapted from Adam Kennedy's work on C<File::ShareDir>

=head1 SEE ALSO

L<File::ShareDir>, L<File::HomeDir>, L<Module::Install>, L<Module::Install::Share>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 Steffen Mueller
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The portions of code that were copied from C<File::ShareDir> are:

Copyright (c) 2005, 2006 Adam Kennedy.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
