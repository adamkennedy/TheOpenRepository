package Archive::Rar;

require 5.002;

use strict;
require Exporter;
use vars ( '@ISA', '@EXPORT', '$VERSION' );

@ISA    = qw(Exporter);
@EXPORT = qw( );

use Data::Dumper;
use Cwd;
use File::Path;

$VERSION = '1.96';

my $IsWindows = ($^O =~ /win32/i ? 1 : 0);

# #-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
# #-
# Objet Archive::Rar.
# #-
# #-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#    RAR exits with a zero code (0) in case of successful operation. The exit
#    code of non-zero means the operation is cancelled due to error:
#
#     255   USER BREAK       User stopped the process
#       8   MEMORY ERROR     Not enough memory for operation
#       7   USER ERROR       Command line option error
#       6   OPEN ERROR       Open file error
#       5   WRITE ERROR      Write to disk error
#       4   LOCKED ARCHIVE   Attempt to modify an archive previously locked
#                            by the 'k' command
#       3   CRC ERROR        A CRC error occurred when unpacking
#       2   FATAL ERROR      A fatal error occurred
#       1   WARNING          Non fatal error(s) occurred
#       0   SUCCESS          Successful operation (User exit)

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ++ fonctions r‚cup‚r‚es dans CHKPROJECT.pm pour en ‚viter l'inclusion.
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# -----------------------------------------------------------------------
# --
# --
sub IsEmpty {
    return 1 if @_ == 0 or not defined $_[0] or $_[0] eq '';
    return undef;
}

# -----------------------------------------------------------------------
#
#
sub CleanDir {
    $_[0] =~ s|\\|/|g   if $IsWindows;
    $_[0] =~ s|/+|/|g;
    $_[0] =~ s|/$||g;
    $_[0] =~ s|:$|:/\.| if $IsWindows;
    $_[0];
}

# ----------------------------------------------------------------
#
#
sub new {
    my $name = shift;

    my $self = bless {}, $name;
    return undef if ( !defined $self->initialize(@_) );
    return $self;
}

# ---------------------------------------------------------------------------
# --
# --
sub WarnOutput {
    my $self = shift;

    return if $self->{silent} or not $self->{dissert};
    my $fh = (defined $self->{stderr} ? $self->{stderr} : \*STDERR);

    print $fh "$_\n" foreach @_;
}

# ---------------------------------------------------------------------------
# --
# --
my $unique_instance;

sub self_or_default {
    return @_
      if defined($_[0]) and !ref($_[0]) and $_[0] eq __PACKAGE__;
    unless ( defined($_[0]) and ref( $_[0] ) eq __PACKAGE__ ) {
        print caller(1);
        $unique_instance = __PACKAGE__->new() unless defined($unique_instance);
        unshift( @_, $unique_instance );
    }
    return @_;
}

# ----------------------------------------------------------------
#
#
sub TestExe {
    my ( $self, $cmd ) = @_;
    my $redirect = '';

    # $redirect =' > NUL:' if $IsWindows;
    # print "--" . system("$cmd $redirect") . "--\n";
    my @r = qx/$cmd/;
    return 1 if $#r > 10;
    return undef;
}

# ----------------------------------------------------------------
#
#
sub SearchExe {
    my $self  = shift;
    my $cmd = 'rar';

    if ( $IsWindows ) {
        my ( $clef, $type, $value );

        # on essaie de piquer le chemin d'install par la clef d'execution.
        if (
            $::HKEY_LOCAL_MACHINE->Open(
                'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe', $clef )
            and $clef->QueryValueEx( "path", $type, $value )
          )
        {
            $value =~ s/\\/\//g;
            $cmd = $value . '/rar.exe';
            goto Good if ( -e $cmd );
        }

        # ou alors par le desinstalleur.
        if (
            $::HKEY_LOCAL_MACHINE->Open(
                'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinRAR archiver', $clef )
            and $clef->QueryValueEx( "UninstallString", $type, $value )
          )
        {
            $value =~ s/\\/\//g;
            $value =~ s/\/uninstall.exe$//i;
            $cmd = $value . '/rar.exe';
            goto Good if -e $cmd;
        }

        # on tente le chemin 'normal'.
        $cmd = 'c:/program files/winrar/rar.exe';
        goto Good if -e $cmd;

        # alors une execution direct.
        $cmd = 'rar';
        goto Good if $self->TestExe($cmd);

        # en dernier recourt...
        $cmd = 'rar32';
        goto Good if $self->TestExe($cmd);
    }
    else {
        $cmd = 'rar';
        goto Good if $self->TestExe($cmd);
        $cmd = './rar';
        goto Good if $self->TestExe($cmd);
    }
  Bad:
    print "ERROR : Can't find rar binary.\n" if $self->{dbg};
    return undef;
  Good:
    $self->{rar} = qq["$cmd"];

    # print "GOOD : '$self->{rar}'\n";
    return $self->{rar};
}

# ----------------------------------------------------------------
#
#
sub initialize {
    my $self     = shift;
    my %params = @_;
    my %args   = (
        -yes     => 1,
        -recurse => 1,
        -mode    => 5,
        -volume  => 1,
        -alldata => 1,
    );

    my ( $clef, $valeur );
    while ( ( $clef, $valeur ) = each(%params) ) {
        $args{$clef} = $valeur;
    }
    $self->{args} = \%args;

    if ( $IsWindows ) {
        require Win32::Registry;
        Win32::Registry->import();
    }
    return $self->SearchExe();
}

# ----------------------------------------------------------------
#
#
sub SetOptions {
    my ( %args, $self, $command, %opts, $s, @exclude, %params, $clef, $valeur );
    $self      = shift;
    $command = shift;
    %args    = %{ $self->{args} };
    %params  = @_;
    while ( ( $clef, $valeur ) = each(%params) ) {
        $args{$clef} = $valeur;
    }
    $self->{current} = \%args;

    $args{'-files'} = $command eq 'vt' ? [] : '.' if ( IsEmpty( $args{'-files'} ) );
    $args{'-files'} = [$args{'-files'}] if ( ref( $args{'-files'} ) eq '' );

    $self->{archive} = $args{'-archive'} if ( !IsEmpty( $args{'-archive'} ) );

    # print "ARCHIVE='$self->{archive}' '$args->{-archive}'\n";
    if ( defined $self->{archive} && $self->{archive} ne '' ) {

        # goto Suite if ($command =~ /^[levx]/i && -f $self->{archive});
        # fixed #32090
        $self->{archive} =~ /\.(\w+)$/;
        my $ext = ".$1";
        $ext = ( $^O eq 'MSWin32' ) ? '.exe' : '.sfx' if ( defined $args{'-sfx'} && $args{'-sfx'} );
        $self->{archive} =~ s/\.\w+$/$ext/;
        $self->{archive} = CleanDir( $self->{archive} );
        my $expr = ( $^O eq 'MSWin32' ) ? '^([a-z_A-Z]:)?\/' : '^\/';
        if ( $self->{archive} !~ /$expr/ ) {
            $self->{archive} = getcwd() . '/' . $self->{archive};
        }
        $self->{archive} = CleanDir( $self->{archive} );
    }
  Suite:
    $self->{archive} =~ s|/|\\|g if ( $^O eq 'MSWin32' );

    # print "ARCHIVE='$self->{archive}'\n";

    # fixed #31835
    $self->{archive} = "\"$self->{archive}\"";
    $self->{options} = '';

    # new feature for using with nice
    $self->{nice} = '';
    if ( $command =~ /^[x]/i ) {
        $self->{nice} .= 'nice'
          if !IsEmpty($args{'-lowprio'})
            and $args{'-lowprio'}
            and $IsWindows;
    }
    if ( $command =~ /^[a]/i ) {
        $self->{options} .= ' -sfx' if ( defined $args{'-sfx'} && $args{'-sfx'} );
        $self->{options} .= ' -r' if ( !IsEmpty( $args{'-recurse'} ) );
        $self->{options} .= ' -m' . $args{'-mode'} if ( !IsEmpty( $args{'-mode'} ) );
        $self->{options} .= ' -v' . $args{'-size'} if ( !IsEmpty( $args{'-size'} ) );
    }
    if ( $command =~ /^[levx]/i ) {
        $self->{options} .= ' -v' if ( !IsEmpty( $args{'-volume'} ) );
    }

    # fixed #32196
    $self->{options} .= ' -ep'   if ( !IsEmpty( $args{'-excludepaths'} ) );
    $self->{options} .= ' -inul' if ( !IsEmpty( $args{'-quiet'} ) );
    $self->{options} .= ' -y'    if ( !IsEmpty( $args{'-yes'} ) );

    # fixed #32623
    $self->{options} .= ' -o-'
      if ( !IsEmpty( $args{'-donotoverwrite'} ) && $args{'-donotoverwrite'} );

    if ( !IsEmpty( $self->{args}->{'-verbose'} ) && $self->{args}->{'-verbose'} > 9 ) {
        print "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n";
        print Dumper $self;
        print "\n'$self->{options}'\n";
        print "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n";
    }
    return 0;
}

# ----------------------------------------------------------------
#
#
sub Add {
    my ( $self, $args, $retour, $res );
    $self = shift;
    $self->{command} = 'a';
    $self->SetOptions( $self->{command}, @_ );

    $args = $self->{current};
    if ( !IsEmpty( $args->{'-initial'} ) ) {
        return $self->SetError( 256, $args->{'-initial'} ) if ( !chdir( $args->{'-initial'} ) );
        $retour = getcwd;
    }
    $res =
      $self->Execute( "$self->{rar} $self->{command} $self->{options} $self->{archive} "
          . join( ' ', @{ $args->{'-files'} } ) );
    if ( $res == 0 and !IsEmpty($retour) ) {
        return $self->SetError( 257, $retour ) if ( !chdir($retour) );
    }
    return $res;
}

# ----------------------------------------------------------------
#
#
sub Extract {
    my ( $self, $args, $retour, $res );
    $self = shift;
    $self->{command} = 'x';
    $self->SetOptions( $self->{command}, @_ );

    $args = $self->{current};
    if ( !IsEmpty( $args->{'-initial'} ) ) {
        mkpath( $args->{'-initial'} );
        return $self->SetError( 256, $args->{'-initial'} ) if ( !chdir( $args->{'-initial'} ) );
        $retour = getcwd;
    }
    $res =
      $self->Execute( "$self->{nice} $self->{rar} $self->{command} $self->{options} $self->{archive} "
          . join( ' ', @{ $args->{'-files'} } ) );
    if ( $res == 0 and !IsEmpty($retour) ) {
        return $self->SetError( 257, $retour ) if ( !chdir($retour) );
    }
    return $res;
}

# ----------------------------------------------------------------
#
#
sub _AddToList {
    my ( $self, $pcurrfile, $pattrib ) = @_;
    return if ( $#$pattrib < 12 );         #fixed #33459
    return if ( $pattrib->[6] =~ /d/i );
    $self->{list} = () if ( !defined $self->{list} );
    if ( $pattrib->[3] =~ /(^<->$)|(^<--$)/ ) {
        $pcurrfile->{packed} += $pattrib->[2];
        $pcurrfile->{parts}++;
    }
    else {
        %$pcurrfile           = ();
        $pcurrfile->{name}    = $pattrib->[0];
        $pcurrfile->{size}    = $pattrib->[1];
        $pcurrfile->{packed}  = $pattrib->[2];
        $pcurrfile->{ratio}   = $pattrib->[3];
        $pcurrfile->{date}    = $pattrib->[4];
        $pcurrfile->{hour}    = $pattrib->[5];
        $pcurrfile->{attr}    = $pattrib->[6];
        $pcurrfile->{crc}     = $pattrib->[7];
        $pcurrfile->{meth}    = $pattrib->[8];
        $pcurrfile->{version} = $pattrib->[9];
        $pcurrfile->{parts}   = 1;
    }
    return if ( $pattrib->[3] =~ /^[<-]->$/ );
    if ( $pcurrfile->{parts} > 1 ) {
        $pcurrfile->{crc} = undef;
        $pcurrfile->{ratio} = sprintf( "%2.0d%%", $pcurrfile->{packed} / $pcurrfile->{size} * 100 );
    }
    $pcurrfile->{ratio} =~ s/%$//;

    # print Dumper $pcurrfile;
    $self->{list} = () if ( !defined $self->{list} );
    if ( !IsEmpty( $self->{current}->{'-alldata'} ) ) {
        push @{ $self->{list} }, {%$pcurrfile};
    }
    else {
        push @{ $self->{list} }, $pcurrfile->{name};
    }
}

# ----------------------------------------------------------------
#
#
sub List {
    my ( $self, $args, $retour, $res, $in, %currfile, @attrib, $file );
    $self            = shift;
    $self->{list}    = undef;
    $self->{command} = 'vt';
    $self->SetOptions( $self->{command}, @_ );

    $args = $self->{current};
    $args->{'-getoutput'} = 1 if ( !defined $args->{'-getoutput'} );
    if ( !IsEmpty( $args->{'-initial'} ) ) {
        return $self->SetError( 256, $args->{'-initial'} ) if ( !chdir( $args->{'-initial'} ) );
        $retour = getcwd;
    }
    $res =
      $self->Execute( "$self->{rar} $self->{command} $self->{options} $self->{archive} "
          . join( ' ', @{ $args->{'-files'} } ) );
    $in = 0;
    my $first;
    foreach ( @{ $self->{output} } ) {
        s/[\s\n\r]+$//;
        next if ( $_ eq '' );
        if (/^-----/) { $first = 0; $in = !$in; next; }
        next if ( !$in );
        if (/^ [^\s]/) {
            s/(^\s+)|(\s+$)//;
            $self->_AddToList( \%currfile, \@attrib );
            @attrib = ();
            push @attrib, $_;
        }
        else {
            push @attrib, split;
        }
    }
    $self->_AddToList( \%currfile, \@attrib );
    if ( $res == 0 and !IsEmpty($retour) ) {
        return $self->SetError( 257, $retour ) if ( !chdir($retour) );
    }
    return $res;
}

# ----------------------------------------------------------------
#
#
sub PrintList {
    my ( $self, $fh ) = @_;

    return
      if not defined $self->{list}
        or ref( $self->{list} ) ne 'ARRAY'
        or ref( $self->{list}->[0] ) ne 'HASH';
    $fh = \*STDOUT if IsEmpty($fh);
    print $fh <<EOD;

+-------------------------------------------------+----------+----------+------+
|                    File                         |   Size   |  Packed  | Gain |
+-------------------------------------------------+----------+----------+------+
EOD
    foreach my $p ( @{ $self->{list} } ) {
        printf $fh (
            "| %-47.47s | %8.8s | %8.8s | %3.3s%% |\n",
            $p->{name}, $p->{size}, $p->{packed}, 100 - $p->{ratio}
        );
    }
    print $fh <<EOD;
+-------------------------------------------------+----------+----------+------+
EOD
}

# ----------------------------------------------------------------
#
#
sub GetHelp {
    my ( $self, %args, $res );
    $self                 = shift;
    $args{'-verbose'}     = 1;
    $args{'-getoutput'}   = 1;
    $self->{current}      = \%args;
    $self->{options}      = '-?';
    $self->{command}      = '?';

    $res = $self->Execute("$self->{rar} $self->{options}");

    return join( '', @{ $self->{output} } );
}

# ----------------------------------------------------------------
#
#
sub Execute {
    my $self = shift;
    $self->{cmd} = shift if ( $#_ > -1 );
    print "$self->{cmd}\n" if ( !IsEmpty( $self->{current}->{'-verbose'} ) );
    return 0 if ( !IsEmpty( $self->{current}->{'-noexec'} ) );

    $self->{output} = undef;
    if ( !IsEmpty( $self->{current}->{'-getoutput'} ) ) {
        my @res = ();
        @res = qx/$self->{cmd}/;

        # print @res;
        $self->{output} = \@res;
        return $self->SetError( $? >> 8 );
    }
    return $self->SetError( system( $self->{cmd} ) >> 8 );
}

# ----------------------------------------------------------------
#
#
sub SetError {
    my $self = shift;
    $self->{err} = shift;

    # For the rar command.
    my %errors = (
      0 => '',
      1 => "WARNING : Non fatal error(s) occurred.",
      2 => "FATAL ERROR : A fatal error occurred.",
      3 => "CRC ERROR : A CRC error occurred when unpacking.",
      4 => "LOCKED ARCHIVE : Attempt to modify an archive previously locked by the 'k' command.",
      5 => "WRITE ERROR : Write to disk error.",
      6 => "OPEN ERROR : Open file error.",
      7 => "USER ERROR : Command line option error.",
      8 => "MEMORY ERROR : Not enough memory for operation.",
      255 => "USER BREAK : User stopped the process.",
      256 => sub {"CHDIR ERROR : '" . $_[0] . "' inaccessible : " . $! . "."},
      257 => sub {"CHDIR ERROR : '" . $_[0] . "' inaccessible : " . $! . "."},
    );
    my $error = $errors{ $self->{'err'} };
    if (not defined $error) {
      $error = sprintf( "%s : UNKNOWN ERROR %08X.", $self->{err}, $self->{err} );
    }
    elsif (not $error) {
      $error = '';
    }
    elsif (ref($error) eq 'CODE') {
      $error = $error->(@_);
    }
    else {
      $error = $self->{'err'} . " : " . $error;
    }
    $self->{errstr} = $error;

    print "$self->{errstr}\n"
      if !IsEmpty( $self->{args}->{'-verbose'} );
    return $self->{err};
}

1;

__END__

=head1 NAME

Archive::Rar - Interface with the 'rar' command

=head1 SUPPORTED PLATFORMS

=over 4

=item *
Windows

=item *
Linux

=back


=head1 SYNOPSIS

 use Archive::Rar;
 my $rar =new Archive::Rar();
 $rar->Add(
	-size => $size_of_parts,
	-archive => $archive_filename,
	-files => \@list_of_files,
 );

To extract files from archive:

 use Archive::Rar;
 my $rar = new Archive::Rar( -archive => $archive );
 $rar->List( );
 my $res = $rar->Extract( );
 print "Error $res in extracting from $archive\n" if ( $res );

To list archived files:

 use Archive::Rar;
 my $rar = new Archive::Rar( -archive => $archive );
 $rar->List( );
 $rar->PrintList( );

Using further options:

 use Archive::Rar;
 my $rar = new Archive::Rar( -archive => $archive );
 my $res = $rar->Extract(-donotoverwrite => 1, -quiet => 1 );
 print "Error $res in extracting from $archive\n" if ( $res );

=head1 DESCRIPTION

This is a module for the handling of rar archives. 

Locates the rar command (from PATH or from regedit for Win32) and encapsulate it to
create, extract and list rar archives.

At the moment these methods are implemented:

=over 4

=item C<new()>

Returns a new Rar object. You can pass defaults options.

=item C<Add(%options)>

Add file to an archive.

=item C<Extract(%options)>

Extract the contains of an archive.

=item C<List(%options)>

Fill the 'list' variable of the object whith the index of an archive.

=back

=head1 OPTIONS

=over 4

=item C<-archive>

Archive filename.

=item C<-files>

List of files to add. You can use a scalar value or an array reference.

=item C<-quiet>

No output for the rar command if True.

=item C<-sfx>

Create self-extracting archive.

=item C<-size>

Size of the parts in bytes.

=item C<-verbose>

Level of verbosity.

=item C<-excludepaths>

Exclude paths from names.

=item C<-donotoverwrite>

Do not overwrite existing files if True.

=item C<-lowprio>

For Unix-like systems only, this options runs the extraction with low scheduling priority, if Ture.

=back

=head1 KNOWN BUGS


=head1 AUTHORS

jean-marc boulade E<lt>jmbperl@hotmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2006 jean-marc boulade. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

=head1 RAR DOCUMENTATION

  "C:/Program Files/WinRAR/rar.exe"

  RAR 2.80    Copyright (c) 1993-2001 Eugene Roshal    2 Mar 2001
  Shareware version         Type RAR -? for help
  
  Usage:     rar <command> -<switch 1> -<switch N> <archive> <files...>
                 <@listfiles...> <path_to_extract\>
  
  <Commands>
    a             Add files to archive
    c             Add archive comment
    cf            Add files comment
    cw            Write archive comment to file
    d             Delete files from archive
    e             Extract files to current directory
    f             Freshen files in archive
    k             Lock archive
    l[t]          List archive [technical]
    m[f]          Move to archive [files only]
    p             Print file to stdout
    r             Repair archive
    rr[N]         Add data recovery record
    s[name|-]     Convert archive to or from SFX
    t             Test archive files
    u             Update files in archive
    v[t]          Verbosely list archive [technical]
    x             Extract files with full path
  
  <Switches>
    -             Stop switches scanning
    ac            Clear Archive attribute after compression or extraction
    ag[format]    Generate archive name using the current date
    ao            Add files with Archive attribute set
    ap<path>      Set path inside archive
    as            Synchronize archive contents
    av            Put authenticity verification (registered versions only)
    av-           Disable authenticity verification check
    c-            Disable comments show
    cfg-          Disable read configuration
    cl            Convert names to lower case
    cu            Convert names to upper case
    df            Delete files after archiving
    dh            Open shared files
    ds            Disable name sort for solid archive
    e<attr>       Set file exclude attributes
    ed            Do not add empty directories
    ep            Exclude paths from names
    ep1           Exclude base directory from names
    ep2           Expand paths to full
    f             Freshen files
    idp           Disable percentage display
    ierr          Send all messages to stderr
    ilog          Log errors to file (registered versions only)
    inul          Disable all messages
    isnd          Enable sound
    k             Lock archive
    kb            Keep broken extracted files
    m<0..5>       Set compression level (0-store...3-default...5-maximal)
    md<size>      Set dictionary size in KB (64,128,256,512,1024 or A,B,C,D,E)
    mm[f]         Multimedia compression [force]
    o+            Overwrite existing files
    o-            Do not overwrite existing files
    os            Save NTFS streams
    ow            Save or restore file owner and group
    p[password]   Set password
    p-            Do not query password
    r             Recurse subdirectories
    r0            Recurse subdirectories for wildcard names only
    ri<P>[:<S>]   Set priority (0-default,1-min..15-max) and sleep time in ms
    rr[N]         Add data recovery record
    s[<N>,d,e]    Create solid archive
    s-            Disable solid archiving
    sfx[name]     Create SFX archive
    tk            Keep original archive time
    tl            Set archive time to latest file
    tn<time>      Add files newer than <time>
    to<time>      Add files older than <time>
    u             Update files
    v             Create volumes with size autodetection or list all volumes
    v<size>[k,b]  Create volumes with size=<size>*1000 [*1024, *1]
    vd            Erase disk contents before creating volume
    vp            Pause before each volume
    w<path>       Assign work directory
    x<file>       Exclude specified file
    x@            Read file names to exclude from stdin
    x@<list>      Exclude files in specified list file
    y             Assume Yes on all queries
    z<file>       Read archive comment from file

=cut
