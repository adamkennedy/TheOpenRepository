package Module::Build::Functions;

#<<<
use     strict;
use     5.005;
use     vars                  
  qw( $VERSION @EXPORT $AUTOLOAD %args @install_types );
use     Carp                  qw( croak carp                       );
use     English               qw( -no_match_vars                   );
use     Exporter              qw( import                           );
use     File::Spec::Functions qw( catdir catfile                   );
use     Config;
use     AutoLoader;
require Module::Build;
#>>>

# The equivalent of "use warnings" pre-5.006.
local $WARNING = 1;
my $object         = undef;
my $class          = undef;
my $mb_required    = 0;
my $autoload       = 1;
my $object_created = 0;
my $sharemod_used  = 1;
my (%FLAGS, %ALIASES, %ARRAY, %HASH, @AUTOLOADED, @DEFINED);

BEGIN {
	$VERSION = '0.001_008';

	# Module implementation here

	# Set defaults.
	if ( $Module::Build::VERSION >= 0.28 ) {
		$args{create_packlist} = 1;
		$mb_required = 0.28;
	}

	%FLAGS = (
		'build_class'          => [ 0.28, 0 ],
		'create_makefile_pl'   => [ 0.19, 0 ],
		'dist_abstract'        => [ 0.20, 0 ],
		'dist_name'            => [ 0.11, 0 ],
		'dist_version'         => [ 0.11, 0 ],
		'dist_version_from'    => [ 0.11, 0 ],
		'installdirs'          => [ 0.19, 0 ],
		'license'              => [ 0.11, 0 ],
		'create_packlist'      => [ 0.28, 1 ],
		'create_readme'        => [ 0.22, 1 ],
		'create_license'       => [ 0.31, 1 ],
		'dynamic_config'       => [ 0.07, 1 ],
		'use_tap_harness'      => [ 0.30, 1 ],
		'sign'                 => [ 0.16, 1 ],
		'recursive_test_files' => [ 0.28, 1 ],
	);

	%ALIASES = (
		'test_requires'       => 'build_requires',
		'abstract'            => 'dist_abstract',
		'name'                => 'module_name',
		'author'              => 'dist_author',
		'version'             => 'dist_version',
		'version_from'        => 'dist_version_from',
		'extra_compiler_flag' => 'extra_compiler_flags',
		'extra_linker_flag'   => 'extra_linker_flags',
		'include_dir'         => 'include_dirs',
		'pl_file'             => 'PL_files',
		'pl_files'            => 'PL_files',
		'PL_file'             => 'PL_files',
		'pm_file'             => 'pm_files',
		'pod_file'            => 'pod_files',
		'xs_file'             => 'xs_files',
		'test_file'           => 'test_files',
		'script_file'         => 'script_files',
	);

	%ARRAY = (
		'autosplit'      => 0.04,
		'add_to_cleanup' => 0.19,
		'include_dirs'   => 0.24,
		'dist_author'    => 0.20,
	);

	%HASH = (
		'configure_requires' => [ 0.30, 1 ],
		'build_requires'     => [ 0.07, 1 ],
		'conflicts'          => [ 0.07, 1 ],
		'recommends'         => [ 0.08, 1 ],
		'requires'           => [ 0.07, 1 ],
		'get_options'        => [ 0.26, 0 ],
		'meta_add'           => [ 0.28, 0 ],
		'meta_merge'         => [ 0.28, 0 ],
		'pm_files'           => [ 0.19, 0 ],
		'pod_files'          => [ 0.19, 0 ],
		'xs_files'           => [ 0.19, 0 ],
		'install_path'       => [ 0.19, 0 ],
	);

	@AUTOLOADED = ( keys %HASH, keys %ARRAY, keys %ALIASES, keys %FLAGS );
	@DEFINED = qw(
	  all_from abstract_from author_from license_from perl_version
	  perl_version_from install_script install_as_core install_as_cpan
	  install_as_site install_as_vendor WriteAll auto_install auto_bundle
	  bundle bundle_deps auto_bundle_deps can_use can_run can_cc
	  requires_external_bin requires_external_cc get_file check_nmake
	  interactive release_testing automated_testing win32 winlike
	  author_context install_share auto_features extra_compiler_flags
	  extra_linker_flags module_name no_index PL_files script_files test_files
	  tap_harness_args subclass create_build_script get_builder
	  functions_self_bundler bundler
	);
	@EXPORT = ( @DEFINED, @AUTOLOADED );
	# print join ' ', 'Exported:', @EXPORT, "\n";
}

# The autoload handles 4 types of "similar" routines, for 45 names.
sub AUTOLOAD {
	my $full_sub = $AUTOLOAD;
	my ($sub) = $AUTOLOAD =~ m{\A.*::([^:]*)\z};

	if ( exists $ALIASES{$sub} ) {
		my $alias = $ALIASES{$sub};
		eval <<"END_OF_CODE";
sub $full_sub {
	$alias(\@_);
	return;
}
END_OF_CODE
		goto &$full_sub;
	}

	if ( exists $FLAGS{$sub} ) {
		my $version  = $FLAGS{$sub}[0];
		my $boolean1 = $FLAGS{$sub}[1] ? '|| 1' : q{};
		my $boolean2 = $FLAGS{$sub}[1] ? q{!!} : q{};
		eval <<"END_OF_CODE";
sub $full_sub {	
	my \$argument = shift $boolean1;
	\$args{$sub} = $boolean2 \$argument;
	_mb_required($version);
	return;
}
END_OF_CODE
		goto &$full_sub;
	} ## end if ( exists $FLAGS{$sub...

	if ( exists $ARRAY{$sub} ) {
#		_create_arrayref($sub);
		my $code = <<"END_OF_CODE";
sub $full_sub {
	my \$argument = shift;
	if ( 'ARRAY' eq ref \$argument ) {
		foreach my \$f ( \@{\$argument} ) {
			$sub(\$f);
		}
		return;
	}
	
	my \@array;
	if (exists \$args{$sub}) {
		\$args{$sub} = [ \@{ \$args{$sub} }, \$argument ];
	} else {
		\$args{$sub} = [ \$argument ];
	}
	_mb_required(\$ARRAY{$sub});
	return;
}
END_OF_CODE
		eval $code;
#		if ($EVAL_ERROR) {
#			print "$@\n";
#			exit;
#		} 
		goto &$full_sub;
	} ## end if ( exists $ARRAY{$sub...

	if ( exists $HASH{$sub} ) {
		_create_hashref($sub);
		my $version = $HASH{$sub}[0];
		my $default = $HASH{$sub}[1] ? '|| 0' : q{};
		eval <<"END_OF_CODE";
sub $full_sub {
	my \$argument1 = shift;
	my \$argument2 = shift $default;
	if ( 'HASH' eq ref \$argument1 ) {
		my ( \$k, \$v );
		while ( ( \$k, \$v ) = each \%{\$argument1} ) {
			$sub( \$k, \$v );
		}
		return;
	}

	\$args{$sub}{\$argument1} = \$argument2;
	_mb_required($version);
	return;
}
END_OF_CODE
		goto &$full_sub;
	} ## end if ( exists $HASH{$sub...

	if ( $autoload == 1 ) {
		$AutoLoader::AUTOLOAD = $full_sub;
		goto &AutoLoader::AUTOLOAD;
	} else {
		croak "$sub cannot be found";
	}
} ## end sub AUTOLOAD

sub _mb_required {
	my $version = shift;
	if ( $version > $mb_required ) {
		$mb_required = $version;
	}
	return;
}

sub _installdir {
	return $Config{'sitelibexp'}   unless ( defined     $args{install_type} );
	return $Config{'sitelibexp'}   if     ( 'site'   eq $args{install_type} );
	return $Config{'privlibexp'}   if     ( 'perl'   eq $args{install_type} );
	return $Config{'vendorlibexp'} if     ( 'vendor' eq $args{install_type} );
	croak 'Invalid install type';
}

sub _create_hashref {
	my $name = shift;
	unless ( exists $args{$name} ) {
		$args{$name} = {};
	}
	return;
}

sub _create_hashref_arrayref {
	my $name1 = shift;
	my $name2 = shift;
	unless ( exists $args{$name1}{$name2} ) {
		$args{$name1}{$name2} = [];
	}
	return;
}

sub _slurp_file {
	my $name = shift;
	my $file_handle;

	if ( $] < 5.006 ) { ## no critic(ProhibitPunctuationVars)
		require Symbol;
		$file_handle = Symbol::gensym();
		open $file_handle, "<$name" ## no critic(RequireBriefOpen)
		  or croak $OS_ERROR;
	} else {
		open $file_handle, '<', $name ## no critic(RequireBriefOpen)
		  or croak $OS_ERROR;
	}

	local $INPUT_RECORD_SEPARATOR = undef;   # enable localized slurp mode
	my $content = <$file_handle>;

	close $file_handle;
	return $content;
} ## end sub _slurp_file

# Module::Install syntax below.

sub all_from {
	my $file = shift;

	abstract_from($file);
	author_from($file);
	version_from($file);
	license_from($file);
	perl_version_from($file);
	return;
}

sub abstract_from {
	my $file = shift;

	require ExtUtils::MM_Unix;
	abstract(
		bless( { DISTNAME => $args{module_name} }, 'ExtUtils::MM_Unix' )
		  ->parse_abstract($file) );

	return;
}

# Borrowed from Module::Install::Metadata->author_from
sub author_from {
	my $file    = shift;
	my $content = _slurp_file($file);
	my $author;
		
	if ($content =~ m{
		=head \d \s+ (?:authors?)\b \s*
		(.*?)
		=head \d
	}ixms) {
		# Grab all author lines.
		my $authors = $1;
		
		# Now break up each line.
		while ($authors =~ m{\G([^\n]+) \s*}gcixms) {
			$author = $1;
			# Convert E<lt> and E<gt> into the right characters.
			$author =~ s{E<lt>}{<}g;
			$author =~ s{E<gt>}{>}g;
			
			# Remove new-style C<< >> markers. 
			if ($author =~ m{\A(.*?) \s* C<< \s* (.*?) \s* >>}msx) {
				$author = "$1 $2";
			}
			dist_author($author);
		}		
	} elsif ($content =~ m{
		=head \d \s+ (?:licen[cs]e|licensing|copyright|legal)\b \s*
		.*? copyright .*? \d\d\d[\d.]+ \s* (?:\bby\b)? \s*
		([^\n]*)
	}ixms) {
		$author = $1;
		# Convert E<lt> and E<gt> into the right characters.
		$author =~ s{E<lt>}{<}g;
		$author =~ s{E<gt>}{>}g;
		
		# Remove new-style C<< >> markers. 
		if ($author =~ m{\A(.*?) \s* C<< \s* (.*?) \s* >>}msx) {
			$author = "$1 $2";
		}
		dist_author($author);
	} else {
		carp "Cannot determine author info from $file";
	}
}

# Borrowed from Module::Install::Metadata->license_from
sub license_from {
	my $file = shift;
	my $content = _slurp_file($file);
	if ($content =~ m{
		(
			=head \d \s+
			(?:licen[cs]e|licensing|copyright|legal)\b
			.*?
		)
		(=head\\d.*|=cut.*|)
		\z
	}ixms ) {
		my $license_text = $1;
		my @phrases      = (
			'under the same (?:terms|license) as perl itself' => 'perl',        1,
			'GNU general public license'                      => 'gpl',         1,
			'GNU public license'                              => 'gpl',         1,
			'GNU lesser general public license'               => 'lgpl',        1,
			'GNU lesser public license'                       => 'lgpl',        1,
			'GNU library general public license'              => 'lgpl',        1,
			'GNU library public license'                      => 'lgpl',        1,
			'BSD license'                                     => 'bsd',         1,
			'Artistic license'                                => 'artistic',    1,
			'GPL'                                             => 'gpl',         1,
			'LGPL'                                            => 'lgpl',        1,
			'BSD'                                             => 'bsd',         1,
			'Artistic'                                        => 'artistic',    1,
			'MIT'                                             => 'mit',         1,
			'proprietary'                                     => 'proprietary', 0,
		);
		while ( my ($pattern, $license, $osi) = splice(@phrases, 0, 3) ) {
			$pattern =~ s{\s+}{\\s+}g;
			if ( $license_text =~ /\b$pattern\b/i ) {
				license($license);
				return;
			}
		}
	}

	carp "Cannot determine license info from $file";
	license('unknown');
	return;
}

sub perl_version {
	requires( 'perl', @_ );
	return;
}

# Borrowed from Module::Install::Metadata->license_from
sub perl_version_from {
	my $file = shift;
	my $content = _slurp_file($file);
	if (
		$content =~ m{
		^  # Start of LINE, not start of STRING.
		(?:use|require) \s*
		v?
		([\d_\.]+)
		\s* ;
		}ixms
	) {
		my $perl_version = $1;
		$perl_version =~ s{_}{}g;
		perl_version($perl_version);
	} else {
		carp "Cannot determine perl version info from $file";
	}

	return;
}

sub install_script {
	croak 'install_script not supported yet';
}

sub install_as_core {
	return installdirs('perl');
}

sub install_as_cpan {
	return installdirs('site');
}

sub install_as_site {
	return installdirs('site');
}

sub install_as_vendor {
	return installdirs('vendor');
}

sub WriteAll { ## no critic(Capitalization)
	my $answer = create_build_script();
	return $answer;
}

# Module::Install::AutoInstall

sub auto_install {
	croak 'auto_install is deprecated';
}

# Module::Install::Bundle

sub auto_bundle {
	croak 'auto_bundle is not supported yet';
}

sub bundle {
	my ( $name, $version ) = @_;

	croak 'bundle is not supported yet';
}

sub bundle_deps {
	my ( $name, $version ) = @_;

	croak 'bundle_deps is not supported yet';
}

sub auto_bundle_deps {
	croak 'auto_bundle_deps is not supported yet';
}

# Module::Install::Can

sub can_use {
	croak 'can_use is not supported yet';
}

sub can_run {
	croak 'can_run is not supported yet';
}

sub can_cc {
	croak 'can_cc is not supported yet';
}

# Module::Install::External

sub requires_external_bin {
	croak 'requires_external_bin is not supported yet';
}

sub requires_external_cc {
	croak 'requires_external_cc is not supported yet';
}

# Module::Install::Fetch

sub get_file {
	croak 'get_file is not supported yet';
}

# Module::Install::Win32

sub check_nmake {
	croak 'check_nmake is not supported yet';
}

# Module::Install::With

sub release_testing {
	return !!$ENV{RELEASE_TESTING};
}

sub automated_testing {
	return !!$ENV{AUTOMATED_TESTING};
}

# Mostly borrowed from Scalar::Util::openhandle, since I should 
# not use modules that were non-core in 5.005.
sub _openhandle {
  my $fh = shift;
  my $rt = reftype($fh) || '';

  return defined(fileno($fh)) ? $fh : undef
    if $rt eq 'IO';

  if ($rt ne 'GLOB') {
    return undef;
  }

  (tied(*$fh) or defined(fileno($fh)))
    ? $fh : undef;
}

# Mostly borrowed from IO::Interactive::is_interactive, since I should 
# not use modules that were non-core in 5.005.
sub interactive {
	# If we're doing automated testing, we assume that we don't have
	# a terminal, even if we otherwise would.
	return 0 if automated_testing();

    # Not interactive if output is not to terminal...
    return 0 if not -t *STDOUT;

    # If *ARGV is opened, we're interactive if...
    if (_openhandle(*ARGV)) {
        # ...it's currently opened to the magic '-' file
        return -t *STDIN if defined $ARGV && $ARGV eq '-';

        # ...it's at end-of-file and the next file is the magic '-' file
        return @ARGV > 0 && $ARGV[0] eq '-' && -t *STDIN if eof *ARGV;

        # ...it's directly attached to the terminal 
        return -t *ARGV;
    }

    # If *ARGV isn't opened, it will be interactive if *STDIN is attached 
    # to a terminal.
    else {
        return -t *STDIN;
    }
}

sub win32 {
	return !!( $OSNAME eq 'MSWin32' );
}

sub winlike {
	return !!( $OSNAME eq 'MSWin32' or $OSNAME eq 'cygwin' );
}

sub author_context {
	return 1 if -d 'inc/.author';
	return 1 if -d '.svn';
	return 1 if -f '.cvsignore';
	return 1 if -f '.gitignore';
	return 1 if -f 'MANIFEST.SKIP';
	return 0;
}

# Module::Install::Share

sub _scan_dir {
	my ($srcdir, $destdir, $unixdir, $type, $files) = @_;

	my $type_files = $type . '_files';
	
	$args{$type_files} = {} unless exists $args{"$type_files"};
	
	my $dir_handle;
	
	if ( $] < 5.006 ) { ## no critic(ProhibitPunctuationVars)
		require Symbol;
		$dir_handle = Symbol::gensym();
	} 
		
	opendir $dir_handle, $srcdir ## no critic(RequireBriefOpen)
	  or croak $OS_ERROR;

  FILE:
	foreach my $direntry (readdir $dir_handle) {
		if (-d $direntry) {
			next FILE if ($direntry eq '.');
			next FILE if ($direntry eq '..');
			_scan_dir( catdir($srcdir, $direntry), catdir($destdir, $direntry), 
			  File::Spec::Unix->catdir($unixdir, $direntry), $type, $files);
		} else {
			my $sourcefile = catfile($srcdir, $direntry);
			my $unixfile = File::Spec::Unix->catfile($unixdir, $direntry);
			if ( exists $files->{$unixfile}) {
				$args{$type_files}{$sourcefile} = catfile($destdir, $direntry);
			}
		}
	}

	closedir $dir_handle;
}

sub install_share {
	my $dir  = @_ ? pop   : 'share';
	my $type = @_ ? shift : 'dist';

	unless ( defined $type and ( ($type eq 'module') or ($type eq 'dist') ) ) {
		croak "Illegal or invalid share dir type '$type'";
	}
	unless ( defined $dir and -d $dir ) {
		croak 'Illegal or missing directory install_share param';
	}

	require File::Spec::Unix;
	require ExtUtils::Manifest;
	my $files = ExtUtils::Manifest::maniread();
	my $installation_path;
	my $sharecode;
	
	if ( $type eq 'dist' ) {
		croak 'Too many parameters to install_share' if @_;

		my $dist = $args{'dist_name'};

		$installation_path =
		  catdir( _installdir(), qw(auto share dist), $dist );
		_scan_dir($dir, 'share', $dir, 'share', $files); 
		push @install_types, 'share';
		$sharecode = 'share';
	} else {
		my $module = shift;

		unless ( defined $module ) {
			croak "Missing or invalid module name '$module'";
		}

		$module =~ s/::/-/g;
		$installation_path =
		  catdir( _installdir(), qw(auto share module), $module );
		$sharecode = 'share_d' . $sharemod_used;
		_scan_dir($dir, $sharecode, $dir, $sharecode, $files); 
		push @install_types, $sharecode;
		$sharemod_used++;
	}

	install_path( $sharecode, $installation_path );
	
	# 99% of the time we don't want to index a shared dir
	no_index($dir);
	return;
} ## end sub install_share

# Module::Build syntax

sub _af_hashref {
	my $feature = shift;
	unless ( exists $args{auto_features} ) {
		$args{auto_features} = {};
	}
	unless ( exists $args{auto_features}{$feature} ) {
		$args{auto_features}{$feature} = {};
		$args{auto_features}{$feature}{requires} = {};
	}
	return;
}

sub auto_features {
	my $feature = shift;
	my $type    = shift;
	my $param1  = shift;
	my $param2  = shift;
	_af_hashref($type);

	if ( 'description' eq $type ) {
		$args{auto_features}{$feature}{description} = $param1;
	} elsif ( 'requires' eq $type ) {
		$args{auto_features}{$feature}{requires}{$param1} = $param2;
	} else {
		croak "Invalid type $type for auto_features";
	}
	_mb_required(0.26);
	return;
} ## end sub auto_features

sub extra_compiler_flags {
	my $flag = shift;
	if ( 'ARRAY' eq ref $flag ) {
		foreach my $f ( @{$flag} ) {
			extra_compiler_flags($f);
		}
	}

	if ( $flag =~ m{\s} ) {
		my @flags = split m{\s+}, $flag;
		foreach my $f (@flags) {
			extra_compiler_flags($f);
		}
	} else {
		_create_arrayref('extra_compiler_flags');
		push @{ $args{'extra_compiler_flags'} }, $flag;
	}
	_mb_required(0.19);
	return;
} ## end sub extra_compiler_flags

sub extra_linker_flags {
	my $flag = shift;
	if ( 'ARRAY' eq ref $flag ) {
		foreach my $f ( @{$flag} ) {
			extra_linker_flags($f);
		}
	}

	if ( $flag =~ m{\s} ) {
		my @flags = split m{\s+}, $flag;
		foreach my $f (@flags) {
			extra_linker_flags($f);
		}
	} else {
		_create_arrayref('extra_linker_flags');
		push @{ $args{'extra_linker_flags'} }, $flag;
	}
	_mb_required(0.19);
	return;
} ## end sub extra_linker_flags

sub module_name {
	my ($name) = shift;
	$args{'module_name'} = $name;
	unless ( exists $args{'dist_name'} ) {
		my $dist_name = $name;
		$dist_name =~ s/::/-/g;
		dist_name($dist_name);
	}
	_mb_required(0.03);
	return;
}

sub no_index {
	my $name = pop;
	my $type = shift || 'directory';

	# TODO: compatibility code.

	_create_hashref('no_index');
	_create_hashref_arrayref( 'no_index', $type );
	push @{ $args{'no_index'}{$type} }, $name;
	_mb_required(0.28);
	return;
} ## end sub no_index

sub PL_files { ## no critic(Capitalization)
	my $pl_file = shift;
	my $pm_file = shift || [];
	if ( 'HASH' eq ref $pl_file ) {
		my ( $k, $v );
		while ( ( $k, $v ) = each %{$pl_file} ) {
			PL_files( $k, $v );
		}
	}

	_create_hashref('PL_files');
	$args{PL_files}{$pl_file} = $pm_file;
	_mb_required(0.06);
	return;
} ## end sub PL_files

sub script_files {
	my $file = shift;
	if ( 'ARRAY' eq ref $file ) {
		foreach my $f ( @{$file} ) {
			script_files($f);
		}
	}

	if ( -d $file ) {
		if ( exists $args{'script_files'} ) {
			if ( 'ARRAY' eq ref $args{'script_files'} ) {
				croak
				  "cannot add directory $file to a list of script_files";
			} else {
				croak
"attempt to overwrite string script_files with $file failed";
			}
		} else {
			$args{'script_files'} = $file;
		}
	} else {
		_create_arrayref('script_files');
		push @{ $args{'script_files'} }, $file;
	}
	_mb_required(0.18);
	return;
} ## end sub script_files

sub test_files {
	my $file = shift;
	if ( 'ARRAY' eq ref $file ) {
		foreach my $f ( @{$file} ) {
			test_files($f);
		}
	}

	if ( $file =~ /[*?]/ ) {
		if ( exists $args{'test_files'} ) {
			if ( 'ARRAY' eq ref $args{'test_files'} ) {
				croak 'cannot add a glob to a list of test_files';
			} else {
				croak 'attempt to overwrite string test_files failed';
			}
		} else {
			$args{'test_files'} = $file;
		}
	} else {
		_create_arrayref('test_files');
		push @{ $args{'test_files'} }, $file;
	}
	_mb_required(0.23);
	return;
} ## end sub test_files

sub tap_harness_args {
	my ($thargs) = shift;
	$args{'tap_harness_args'} = $thargs;
	use_tap_harness(1);
	return;
}

sub subclass {
	$class = Module::Build->subclass(@_);
	return;
}

sub create_build_script {
	get_builder();
	$object->create_build_script;
	return $object;
}

# Required to get a builder for later use.
sub get_builder {
#	require Data::Dumper;
#	my $d = Data::Dumper->new([\%args], [qw(*args)]);
#	print $d->Indent(1)->Dump();
	unless ( defined $object ) {
		if ( defined $class ) {
			$object = $class->new(%args);
		} else {
			$object = Module::Build->new(%args);
		}
		$object_created = 1;
	}
	
	foreach my $type (@install_types) {
		$object->add_build_element($type);
	}
	
	return $object;
}

sub functions_self_bundler {
	my $code = <<'END_OF_CODE';
sub ACTION_distmeta {
	my $self = shift;
	require Module::Build::Functions;
	Module::Build::Functions::bundler();
    $self->SUPER::ACTION_distmeta();
}
END_OF_CODE

	subclass(
		class => 'ModuleBuildFunctions::SelfBundler',
		code  => $code
	);

	return;
} ## end sub functions_self_bundler

__END__

sub bundler {
	require File::Slurp;
	require File::Spec;
	require File::Path;
	File::Slurp->import(qw(read_file write_file));
	File::Path->import(qw(mkpath));
	my ( $fulldir, $file, $text, $outfile );
  DIRLOOP:

	foreach my $dir ( $Config{'sitelibexp'}, $Config{'vendorlibexp'},
		$Config{'privlibexp'} )
	{
		$fulldir = File::Spec->catdir( $dir, qw(Module Build) );
		$file = File::Spec->catfile( $fulldir, 'Functions.pm' );
		if ( -f $file ) {
			$text = read_file($file);
			$text =~ s/package [ ] Module/package inc::Module/msx;
			$text =~ s/use [ ]* AutoLoader;//msx;
			$text =~ s/my [ ] \$autoload [ ]* = [ ] 1/my \$autoload =       0/msx;
			$text =~ s/__END__.*/\n/ms;
			$text =~ s/__END__.*/\n/msx;
			$fulldir = File::Spec->catdir(qw(inc Module Build));
			$outfile = File::Spec->catfile( $fulldir, 'Functions.pm' );
			mkpath( $fulldir, 0, 0644 );
			print "Writing $outfile\n";
			write_file( $outfile, $text );
			last DIRLOOP;
		} ## end if ( -f $file )
	} ## end foreach my $dir ( $Config{'sitelibexp'...
	mkdir File::Spec->catdir(qw(inc .author));
	return;
} ## end sub bundler

1;                                     # Magic true value required at end of module

__END__