package Archive::Rar;

require 5.002;

use strict;
require Exporter;
use vars ('@ISA', '@EXPORT', '$VERSION', '$version');

@ISA = qw(Exporter);
@EXPORT = qw( );

use Data::Dumper;
use Cwd;
use File::Path;

$VERSION = '1.91';
$version ="V$VERSION 24/03/2002 (Perl $] $^O)";

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
	return 1 if ($#_ < 0 || !defined $_[0] || $_[0] eq '');
	return undef;
}
# -----------------------------------------------------------------------
#  
# 
sub CleanDir {
	$_[0] =~ s|\\|/|g  if ($^O eq 'MSWin32');
	$_[0] =~ s|/+|/|g;
	$_[0] =~ s|/$||g;
	$_[0] =~s|:$|:/\.| if ($^O eq 'MSWin32');
	$_[0];
}


# ----------------------------------------------------------------
#  
# 
sub new {
	my $name = shift;
	
	my $me = bless {
	}, $name;
	return undef if (!defined $me->initialize(@_));
	return $me;
}

# ---------------------------------------------------------------------------
# --  
# -- 
sub WarnOutput {
	my $me =shift;
	
	return if ($me->{silent} || !$me->{dissert});
    my $fh;
    if (!defined $me->{stderr}) {$fh=\*STDERR;} else {$fh=$me->{stderr};}
	foreach (@_) {
		 print $fh "$_\n";
	}
}
# ---------------------------------------------------------------------------
# --  
# -- 
my $unique_instance;
sub self_or_default {
    return @_ if defined($_[0]) && (!ref($_[0])) &&($_[0] eq __PACKAGE__);
	unless (defined($_[0]) && ref($_[0]) eq __PACKAGE__) {
		print caller(1);
		$unique_instance = __PACKAGE__->new() unless defined($unique_instance);
		unshift(@_,$unique_instance);
	}
    return @_;
}
# ----------------------------------------------------------------
#  
# 
sub TestExe {
	my ($me,$cmd) =@_;
	my $redirect ='';
	# $redirect =' > NUL:' if ($me->{sys} eq 'w');
	# print "--" . system("$cmd $redirect") . "--\n";
	my @r =qx/$cmd/;
	return 1 if ($#r > 10);
	return undef;
	print "$#r \n";
	# foreach (@r) { print "-- $_"; };
	
}
# ----------------------------------------------------------------
#  
# 
sub SearchExe {
	my $me =shift;
	my $cmd ='rar';
	
    if ($me->{sys} eq 'w') {
    	my ($clef,$type,$value);
    	# on essaie de piquer le chemin d'install par la clef d'execution.
    	if ($::HKEY_LOCAL_MACHINE->Open('SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe', $clef)
    		&& $clef->QueryValueEx("path", $type, $value)) {
		    $value =~ s/\\/\//g;
		    $cmd =$value . '/rar.exe';
		    goto Good if (-e $cmd);
    	}
    	# ou alors par le desinstalleur.
    	if ($::HKEY_LOCAL_MACHINE->Open('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinRAR archiver', $clef)
    		&& $clef->QueryValueEx("UninstallString", $type, $value)) {
		    $value =~ s/\\/\//g;
		    $value =~ s/\/uninstall.exe$//i;
		    $cmd =$value . '/rar.exe';
		    goto Good if (-e $cmd);
    	}
    	# on tente le chemin 'normal'.
	    $cmd ='c:/program files/winrar/rar.exe';
	    goto Good if (-e $cmd);
    	# alors une execution direct.
		$cmd ='rar';
		goto Good if ($me->TestExe($cmd));
    	# en dernier recourt...
		$cmd ='rar32';
		goto Good if ($me->TestExe($cmd));
   } else {
		$cmd ='rar';
		goto Good if ($me->TestExe($cmd));
		$cmd ='./rar';
		goto Good if ($me->TestExe($cmd));
   }
Bad:
	print "ERROR : Can't find rar binary.\n" if $me->{dbg};
	return undef;
Good:
	$me->{rar} =qq["$cmd"];
	# print "GOOD : '$me->{rar}'\n";
	return $me->{rar};
}
# ----------------------------------------------------------------
#  
# 
sub initialize {
	my ($me,%params,%args,$clef,$valeur);
	$me =shift;
	%params =@_;
	%args =(
		-yes =>1,
		-recurse =>1,
		-mode => 5,
		-overwrite => 1,
		-volume => 1,
		-alldata => 1,
		);
	while ( ($clef,$valeur) =each(%params)) {
		$args{$clef} =$valeur;
	}
	$me->{args} =\%args;
		
    if ($^O eq 'MSWin32') {
    	# use Win32::Registry;
		eval("use Win32::Registry");
		if ($@ ne '') {
			die "Cannot load module Win32::Registry";
		}
    	$me->{sys} ='w';
    } else {
    	$me->{sys} ='';
    }
    return $me->SearchExe();
}
# ----------------------------------------------------------------
#  
# 
sub SetOptions {
	my (%args,$me,$command,%opts,$s,@exclude,%params,$clef,$valeur);
	$me =shift;
	$command =shift;
	%args =%{ $me->{args} };
	%params =@_;
	while (($clef,$valeur) =each(%params)) {
		$args{$clef} =$valeur;
	}
	$me->{current} =\%args;

	$args{'-files'} ='.' if (IsEmpty($args{'-files'}));
	$args{'-files'} =[ $args{'-files'} ] if (ref($args{'-files'}) eq '');

	$me->{archive} =$args{'-archive'} if (!IsEmpty($args{'-archive'}));
	# print "ARCHIVE='$me->{archive}' '$args->{-archive}'\n";
	if (defined $me->{archive} && $me->{archive} ne '') {
		# goto Suite if ($command =~ /^[levx]/i && -f $me->{archive});
		my $ext ='.rar';
		$ext =($^O eq 'MSWin32') ? '.exe' : '.sfx' if (defined $args{'-sfx'} && $args{'-sfx'});
		$me->{archive} =~ s/\.\w+$/$ext/;
		$me->{archive} =CleanDir($me->{archive});
		my $expr =($^O eq 'MSWin32') ? '^([a-z_A-Z]:)?\/': '^\/';
		if ($me->{archive} !~ /$expr/) {
			$me->{archive} =getcwd() . '/' . $me->{archive};
		}
		$me->{archive} =CleanDir($me->{archive});
	}
Suite:
	$me->{archive} =~ s|/|\\|g  if ($^O eq 'MSWin32');
	# print "ARCHIVE='$me->{archive}'\n";


	$me->{options} ='';
	if ($command =~ /^[a]/i) {
		$me->{options} .=' -sfx' if (defined $args{'-sfx'} && $args{'-sfx'});
		$me->{options} .=' -r' if (!IsEmpty($args{'-recurse'}));
		$me->{options} .=' -m' . $args{'-mode'} if (!IsEmpty($args{'-mode'}));
		$me->{options} .=' -v' . $args{'-size'} if (!IsEmpty($args{'-size'}));
	}
	if ($command =~ /^[levx]/i) {
		$me->{options} .=' -v' if (!IsEmpty($args{'-volume'}));
	}
	$me->{options} .=' -inul' if (!IsEmpty($args{'-quiet'}));
	$me->{options} .=' -y' if (!IsEmpty($args{'-yes'}));
	$me->{options} .=' -o+' if (!IsEmpty($args{'-overwrite'}));
	
	if (!IsEmpty($me->{args}->{'-verbose'}) && $me->{args}->{'-verbose'} > 9) {
		print "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n";
		print Dumper $me;
		print "\n'$me->{options}'\n";
		print "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n";
	}
	return 0;
}
# ----------------------------------------------------------------
#  
# 
sub Add {
	my ($me,$args,$retour,$res);
	$me =shift;
	$me->{command} ='a';
	$me->SetOptions($me->{command},@_);
	
	$args =$me->{current};
	if (!IsEmpty($args->{'-initial'})) {
		return $me->SetError(256,$args->{'-initial'}) if (!chdir($args->{'-initial'}));
		$retour =getcwd;
	}
	$res =$me->Execute("$me->{rar} $me->{command} $me->{options} $me->{archive} " . join(' ',@{$args->{'-files'}}));
	goto Fin if ($res != 0);
	if (!IsEmpty($retour)) {
		return $me->SetError(257,$retour) if (!chdir($retour));
	}
Fin:
	return $res;
}
# ----------------------------------------------------------------
#  
# 
sub Extract {
	my ($me,$args,$retour,$res);
	$me =shift;
	$me->{command} ='x';
	$me->SetOptions($me->{command},@_);
	
	$args =$me->{current};
	if (!IsEmpty($args->{'-initial'})) {
		mkpath($args->{'-initial'});
		return $me->SetError(256,$args->{'-initial'}) if (!chdir($args->{'-initial'}));
		$retour =getcwd;
	}
	$res =$me->Execute("$me->{rar} $me->{command} $me->{options} $me->{archive} " . join(' ',@{$args->{'-files'}}));
	goto Fin if ($res != 0);
	if (!IsEmpty($retour)) {
		return $me->SetError(257,$retour) if (!chdir($retour));
	}
Fin:
	return $res;
}
# ----------------------------------------------------------------
#  
# 
sub _AddToList {
	my ($me,$pcurrfile,$pattrib) =@_;
	return if ($pattrib->[6] =~ /d/i);
	return if ($#$pattrib < 0);
	$me->{list} =() if (!defined $me->{list});
	if ($pattrib->[3] =~ /(^<->$)|(^<--$)/) {
		$pcurrfile->{packed} +=$pattrib->[2];
		$pcurrfile->{parts}++;
	} else {
		%$pcurrfile =();
		$pcurrfile->{name} =$pattrib->[0];
		$pcurrfile->{size} =$pattrib->[1];
		$pcurrfile->{packed} =$pattrib->[2];
		$pcurrfile->{ratio} =$pattrib->[3];
		$pcurrfile->{date} =$pattrib->[4];
		$pcurrfile->{hour} =$pattrib->[5];
		$pcurrfile->{attr} =$pattrib->[6];
		$pcurrfile->{crc} =$pattrib->[7];
		$pcurrfile->{meth} =$pattrib->[8];
		$pcurrfile->{version} =$pattrib->[9];
		$pcurrfile->{parts} =1;
	}
	return if ($pattrib->[3] =~ /^[<-]->$/);
	if ($pcurrfile->{parts} > 1) {
		$pcurrfile->{crc} =undef;
		$pcurrfile->{ratio} =sprintf("%2.0d%%",$pcurrfile->{packed}/$pcurrfile->{size}*100);
	}
	$pcurrfile->{ratio} =~ s/%$//;
	# print Dumper $pcurrfile;
	$me->{list} =() if (!defined $me->{list});
	if (!IsEmpty($me->{current}->{'-alldata'})) {
		push @{$me->{list}}, { %$pcurrfile };
	} else {
		push @{$me->{list}},$pcurrfile->{name};
	}
}
# ----------------------------------------------------------------
#  
# 
sub List {
	my ($me,$args,$retour,$res,$in,%currfile,@attrib,$file);
	$me =shift;
	$me->{list} =undef;
	$me->{command} ='vt';
	$me->SetOptions($me->{command},@_);
	
	$args =$me->{current};
	$args->{'-getoutput'} =1 if (!defined $args->{'-getoutput'});
	if (!IsEmpty($args->{'-initial'})) {
		return $me->SetError(256,$args->{'-initial'}) if (!chdir($args->{'-initial'}));
		$retour =getcwd;
	}
	$res =$me->Execute("$me->{rar} $me->{command} $me->{options} $me->{archive} " . join(' ',@{$args->{'-files'}}));
	$in =0;
    my $first;
	foreach (@{$me->{output}}) {
		s/[\s\n\r]+$//;
		next if ($_ eq '');
		if (/^-----/) {	$first =0; $in =!$in; next;}
		next if (!$in);
		if (/^ [^\s]/) {
			s/(^\s+)|(\s+$)//;
			$me->_AddToList(\%currfile,\@attrib);
			@attrib = ();
			push @attrib,$_;
		} else {
			push @attrib,split;
		}
	}
	$me->_AddToList(\%currfile,\@attrib);
	goto Fin if ($res != 0);
	if (!IsEmpty($retour)) {
		return $me->SetError(257,$retour) if (!chdir($retour));
	}
Fin:
	return $res;
}
# ----------------------------------------------------------------
#  
# 
sub PrintList {
	my ($me,$fh) =@_;
	
	return if (!defined $me->{list} || ref($me->{list}) ne 'ARRAY' || ref($me->{list}->[0]) ne 'HASH');
	$fh =\*STDOUT if (IsEmpty($fh));
	print $fh <<EOD;
+------------------------------------------+----------+----------+------+
|                File                      |   Size   |  Packed  | Gain |
+------------------------------------------+----------+----------+------+
EOD
	foreach my $p (@{$me->{list}}) {
		printf $fh ("| %-40.40s | %8.8s | %8.8s | %3.3s% |\n",$p->{name},$p->{size},$p->{packed},100-$p->{ratio});
	}
	print $fh <<EOD;
+------------------------------------------+----------+----------+------+
EOD
}
# ----------------------------------------------------------------
#  
# 
sub GetHelp {
	my ($me,%args,$res);
	$me =shift;
	$args{'-verbose'} =1;
	$args{'-getoutput'} =1;
	$me->{current} =\%args;
	$me->{options} ='-?';
	$me->{command} ='?';
	
	$res =$me->Execute("$me->{rar} $me->{options}");
	
	return join('',@{$me->{output}});
}
# ----------------------------------------------------------------
#  
# 
sub Execute {
	my $me =shift;
	$me->{cmd} =shift if ($#_ > -1);
	print "$me->{cmd}\n" if (!IsEmpty($me->{current}->{'-verbose'}));
	return 0 if (!IsEmpty($me->{current}->{'-noexec'}));

	$me->{output} =undef;
	if (!IsEmpty($me->{current}->{'-getoutput'})) {
		my @res =();
		@res =qx/$me->{cmd}/;
		# print @res;
		$me->{output} =\@res;
		return $me->SetError($? >> 8);	
	}
	return $me->SetError(system($me->{cmd}) >> 8);
}
# ----------------------------------------------------------------
#  
# 
sub SetError {
	my $me =shift;
	$me->{err} =shift;

	# For the rar command.
	if($me->{err}==0){$me->{errstr}=''; goto Fin;}
	if($me->{err}==1){$me->{errstr}="$me->{err} : WARNING : Non fatal error(s) occurred."; goto Fin;}
	if($me->{err}==2){$me->{errstr}="$me->{err} : FATAL ERROR : A fatal error occurred."; goto Fin;}
	if($me->{err}==3){$me->{errstr}="$me->{err} : CRC ERROR : A CRC error occurred when unpacking."; goto Fin;}
	if($me->{err}==4){$me->{errstr}="$me->{err} : LOCKED ARCHIVE : Attempt to modify an archive previously locked by the 'k' command."; goto Fin;}
	if($me->{err}==5){$me->{errstr}="$me->{err} : WRITE ERROR : Write to disk error."; goto Fin;}
	if($me->{err}==6){$me->{errstr}="$me->{err} : OPEN ERROR : Open file error."; goto Fin;}
	if($me->{err}==7){$me->{errstr}="$me->{err} : USER ERROR : Command line option error."; goto Fin;}
	if($me->{err}==8){$me->{errstr}="$me->{err} : MEMORY ERROR : Not enough memory for operation."; goto Fin;}
	if($me->{err}==255) {$me->{errstr}="$me->{err} : USER BREAK : User stopped the process."; goto Fin;}

	# For the module.
	if($me->{err}==256) {$me->{errstr}="$me->{err} : CHDIR ERROR : '$_[0]' inaccessible : $!."; goto Fin;}
	if($me->{err}==257) {$me->{errstr}="$me->{err} : CHDIR ERROR : '$_[0]' inaccessible : $!."; goto Fin;}


	$me->{errstr} =sprintf("%s : UNKNOWN ERROR %08X.",$me->{err},$me->{err});
	
Fin:
	print "$me->{errstr}\n" if (!IsEmpty($me->{args}->{'-verbose'}));
	return $me->{err};
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
