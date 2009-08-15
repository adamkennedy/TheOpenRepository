package Module::Starter::CSJEWELL;

use 5.008001;
use warnings;
use strict;
use Carp;
use English qw( -no_match_vars );
use parent 'Module::Starter::Simple';

our $VERSION = '0.100';
$VERSION = eval { return $VERSION };

sub module_guts {
	my $self    = shift;
	my %context = (
		'MODULE NAME' => shift,
		'RT NAME'     => shift,
		'DATE'        => scalar localtime,
		'YEAR'        => $self->_thisyear(),
	);

	return $self->_load_and_expand_template( 'Module.pm', \%context );
}

sub create_Makefile_PL {
	my $self = shift;

	# We don't create a Makefile.PL.

	return;
}

sub Build_PL_guts {
	my $self    = shift;
	my %context = (
		'MAIN MODULE'  => shift,
		'MAIN PM FILE' => shift,
		'DATE'         => scalar localtime,
		'YEAR'         => $self->_thisyear(),
	);

	return $self->_load_and_expand_template( 'Build.PL', \%context );
}

sub Changes_guts {
	my $self = shift;

	my %context = (
		'DATE' => scalar localtime,
		'YEAR' => $self->_thisyear(),
	);

	return $self->_load_and_expand_template( 'Changes', \%context );
}

sub create_README {
	my $self = shift;

	# We don't create a readme as such.

	return;
}

sub t_guts { ## no critic (RequireArgUnpacking)
	my $self    = shift;
	my @modules = @_;
	my %context = (
		'DATE' => scalar localtime,
		'YEAR' => $self->_thisyear(),
	);

	my %t_files;
	my @template_files;
	push @template_files, glob "$self->{template_dir}/t/*.t";
	push @template_files, glob "$self->{template_dir}/t/settings/*.txt";
	for my $test_file ( map { my $x = $_; $x =~ s{\A .*/t/}{}xms; $x; }
		@template_files )
	{
		$t_files{$test_file} =
		  $self->_load_and_expand_template( "t/$test_file", \%context );
	}

	my $nmodules = @modules;
	$nmodules++;
	my $main_module = $modules[0];
	my $use_lines = join "\n", map {"    use_ok( '$_' );"} @modules;

	$t_files{'000_load.t'} = <<"END_LOAD";
use Test::More tests => $nmodules;

BEGIN {
	use strict;
	\$^W = 1;
	\$| = 1;

    ok((\$] > 5.008000), 'Perl version acceptable') or BAIL_OUT ('Perl version unacceptably old.');
$use_lines
    diag( "Testing $main_module \$${main_module}::VERSION" );
}

END_LOAD

	return %t_files;
} ## end sub t_guts

sub _create_t {
	my $self     = shift;
	my $filename = shift;
	my $content  = shift;

	my @dirparts = ( $self->{basedir}, 't' );
	my $tdir = File::Spec->catdir(@dirparts);
	if ( not -d $tdir ) {
		local @ARGV = $tdir;
		mkpath();
		$self->progress("Created $tdir");
	}

	my @dirparts_s = ( $self->{basedir}, 't', 'settings' );
	my $tdir_s = File::Spec->catdir(@dirparts_s);
	$self->progress("Directory: $tdir_s");
	if ( not -d $tdir_s ) {
		local @ARGV = $tdir_s;
		mkpath();
		$self->progress("Created $tdir_s");
	}

	my $fname = File::Spec->catfile( @dirparts, $filename );
	$self->create_file( $fname, $content );
	$self->progress("Created $fname");

	return "t/$filename";
} ## end sub _create_t

sub MANIFEST_guts { ## no critic (RequireArgUnpacking)
	my $self  = shift;
	my @files = sort @_;

	my $mskip = $self->_load_and_expand_template( 'MANIFEST.SKIP', {} );
	my $fname = File::Spec->catfile( $self->{basedir}, 'MANIFEST.SKIP' );
	$self->create_file( $fname, $mskip );
	$self->progress("Created $fname");

	return join "\n", @files, q{};
}


sub _load_and_expand_template {
	my ( $self, $rel_file_path, $context_ref ) = @_;

	@{$context_ref}{ map {uc} keys %{$self} } = values %{$self};

	die
"Can't find directory that holds Module::Starter::CSJEWELL templates\n",
	  "(no 'template_dir: <directory path>' in config file)\n"
	  if not defined $self->{template_dir};

	die "Can't access Module::Starter::CSJEWELL template directory\n",
"(perhaps 'template_dir: $self->{template_dir}' is wrong in config file?)\n"
	  if not -d $self->{template_dir};

	my $abs_file_path = "$self->{template_dir}/$rel_file_path";

	die "The Module::Starter::CSJEWELL template: $rel_file_path\n",
	  "isn't in the template directory ($self->{template_dir})\n\n"
	  if not -e $abs_file_path;

	die "The Module::Starter::CSJEWELL template: $rel_file_path\n",
	  "isn't readable in the template directory ($self->{template_dir})\n\n"
	  if not -r $abs_file_path;

	open my $fh, '<', $abs_file_path or croak $ERRNO;
	local $INPUT_RECORD_SEPARATOR = undef;
	my $text = <$fh>;
	close $fh or croak $ERRNO;

	$text =~ s{<([A-Z ]+)>}
              { $context_ref->{$1}
                || die "Unknown placeholder <$1> in $rel_file_path\n"
              }xmseg;

	return $text;
} ## end sub _load_and_expand_template

sub import { ## no critic (RequireArgUnpacking ProhibitExcessComplexity)
	my $class = shift;
	my ( $setup, @other_args ) = @_;

	# If this is not a setup request,
	# refer the import request up the hierarchy...
	if ( @other_args || !$setup || $setup ne 'setup' ) {
		return $class->SUPER::import(@_);
	}

	## no critic (RequireLocalizedPunctuationVars ProhibitLocalVars)

	# Otherwise, gather the necessary tools...
	use ExtUtils::Command qw( mkpath );
	use File::Spec;
	local $OUTPUT_AUTOFLUSH = 1;

	local $ENV{HOME} = $ENV{HOME};

	if ( $OSNAME eq 'MSWin32' ) {
		if ( defined $ENV{HOME} ) {
			$ENV{HOME} = Win32::GetShortPathName( $ENV{HOME} );
		} else {
			$ENV{HOME} = Win32::GetShortPathName(
				File::Spec->catpath( $ENV{HOMEDRIVE}, $ENV{HOMEPATH}, q{} )
			);
		}
	}

	# Locate the home directory...
	if ( !defined $ENV{HOME} ) {
		print 'Please enter the full path of your home directory: ';
		$ENV{HOME} = <>;
		chomp $ENV{HOME};
		croak 'Not a valid directory. Aborting.'
		  if !-d $ENV{HOME};
	}

	# Create the directories...
	my $template_dir =
	  File::Spec->catdir( $ENV{HOME}, '.module-starter', 'CSJEWELL' );
	if ( not -d $template_dir ) {
		print {*STDERR} "Creating $template_dir...";
		local @ARGV = $template_dir;
		mkpath;
		print {*STDERR} "done.\n";
	}

	my $template_test_dir =
	  File::Spec->catdir( $ENV{HOME}, '.module-starter', 'CSJEWELL', 't' );
	if ( not -d $template_test_dir ) {
		print {*STDERR} "Creating $template_test_dir...";
		local @ARGV = $template_test_dir;
		mkpath;
		print {*STDERR} "done.\n";
	}

	my $template_test_settings =
	  File::Spec->catdir( $ENV{HOME}, '.module-starter', 'CSJEWELL', 't',
		'settings' );
	if ( not -d $template_test_settings ) {
		print {*STDERR} "Creating $template_test_settings...";
		local @ARGV = $template_test_settings;
		mkpath;
		print {*STDERR} "done.\n";
	}

	# Create or update the config file (making a backup, of course)...
	my $config_file =
	  File::Spec->catfile( $ENV{HOME}, '.module-starter', 'config' );

	my @config_info;

	if ( -e $config_file ) {
		print {*STDERR} "Backing up $config_file...";
		my $backup =
		  File::Spec->catfile( $ENV{HOME}, '.module-starter',
			'config.bak' );
		rename $config_file, $backup or croak $ERRNO;
		print {*STDERR} "done.\n";

		print {*STDERR} "Updating $config_file...";
		open my $fh, '<', $backup or die "$config_file: $!\n";
		@config_info =
		  grep { not /\A (?: template_dir | plugins ) : /xms } <$fh>;
		close $fh or die "$config_file: $!\n";
	} else {
		print {*STDERR} "Creating $config_file...\n";

		my $author = _prompt_for('your full name');
		my $email  = _prompt_for('an email address');

		@config_info = (
			"author:  $author\n",
			"email:   $email\n",
			"builder: Module::Build\n",
		);

		print {*STDERR} "Writing $config_file...\n";
	} ## end else [ if ( -e $config_file )]

	push @config_info,
	  ( "plugins: Module::Starter::CSJEWELL\n",
		"template_dir: $template_dir\n",
	  );

	open my $fh, '>', $config_file or die "$config_file: $!\n";
	print {$fh} @config_info or die "$config_file: $!\n";
	close $fh or die "$config_file: $!\n";
	print {*STDERR} "done.\n";

	print {*STDERR} "Installing templates...\n";

	# Then install the various files...
	my @files = (
		['Build.PL'],
		['Changes'],
		['Module.pm'],
		['MANIFEST.SKIP'],
		[ 't', 'settings', 'perltidy.txt' ],
		[ 't', 'settings', 'perlcritic.txt' ],
		[ 't', '899_prereq.t' ],
		[ 't', '806_portability.t' ],
		[ 't', '805_meta.t' ],
		[ 't', '804_manifest.t' ],
		[ 't', '803_minimumversion.t' ],
		[ 't', '802_pod_coverage.t' ],
		[ 't', '801_pod.t' ],
		[ 't', '800_perlcritic.t' ],
	);

	my %contents_of = do {
		local $INPUT_RECORD_SEPARATOR = undef;
		( q{}, split m{_____\[ [ ] (\S+) [ ] \]_+\n}smx, <DATA> );
	};

	for ( values %contents_of ) {
		s/^!=([a-z])/=$1/gxms;
	}

	for my $ref_path (@files) {
		my $abs_path =
		  File::Spec->catfile( $ENV{HOME}, '.module-starter', 'CSJEWELL',
			@{$ref_path} );
		print {*STDERR} "\t$abs_path...";
		open my $fh, '>', $abs_path or die "$abs_path: $!\n";
		print {$fh} $contents_of{ $ref_path->[-1] }
		  or die "$abs_path: $!\n";
		close $fh or die "$abs_path: $!\n";
		print {*STDERR} "done\n";
	}
	print {*STDERR} "Installation complete.\n";

	exit;
} ## end sub import

sub _prompt_for {
	my ($requested_info) = @_;
	my $response;
  RESPONSE: while (1) {
		print "Please enter $requested_info: ";
		$response = <>;
		if ( not defined $response ) {
			warn "\n[Installation cancelled]\n";
			exit;
		}
		$response =~ s/\A \s+ | \s+ \Z//gxms;
		last RESPONSE if $response =~ m{\S}sm;
	}
	return $response;
} ## end sub _prompt_for


1;                                     # Magic true value required at end of module

__DATA__
_____[ Build.PL ]________________________________________________
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name              => '<MAIN MODULE>',
    license                  => '<LICENSE>',
    dist_author              => '<AUTHOR> <<EMAIL>>',
    dist_version_from        => '<MAIN PM FILE>',
	create_readme            => 1,
	create_license           => 1,
	create_makefile_pl       => 'passthrough',
	configure_requires  => {
        'Module::Build'       => '0.33',
	},
    requires => {
        'perl'                => 5.008001,	
#        'parent'              => '0.221',
#        'Exception::Class'    => '1.29',
    },
	build_requires => {
        'Test::More'          => '0.61',
	},
    meta_merge     => {
        resources => {
            homepage    => 'http://www.no-home-page.invalid/',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=<DISTRO>',
            repository  => 'http://www.no-source-code-repository.invalid/'
        },
    },
    add_to_cleanup      => [ '<DISTRO>-*', ],
);

$builder->create_build_script();
_____[ Changes ]_________________________________________________
Revision history for <DISTRO>

0.001  <DATE>
       Initial release.

_____[ 899_prereq.t ]____________________________________________
#!perl

# Test that all our prerequisites are defined in the Build.PL.

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Prereq::Build 1.036',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

local $ENV{PERL_MM_USE_DEFAULT} = 1;

diag('Takes a few minutes...');

my @modules_skip = (
# Modules needed for prerequisites, not for this module
    # List here if needed.
# Needed only for AUTHOR_TEST tests
	'Parse::CPAN::Meta',
	'Perl::Critic',
	'Perl::Critic::More',
	'Perl::Critic::Utils::Constants',
	'Perl::MinimumVersion',
	'Perl::Tidy',
	'Pod::Coverage::Moose',
	'Pod::Coverage',
	'Pod::Simple',
	'Test::CPAN::Meta',
	'Test::DistManifest',
	'Test::MinimumVersion',
	'Test::Perl::Critic',
	'Test::Pod',
	'Test::Pod::Coverage',
	'Test::Portability::Files',
	'Test::Prereq::Build',
);

prereq_ok(5.008001, 'Check prerequisites', \@modules_skip);

_____[ 806_portability.t ]_______________________________________
#!perl

# Test that our files are portable across systems.

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Portability::Files 0.05',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

run_tests();

_____[ 805_meta.t ]______________________________________________
#!perl

# Test that our META.yml file matches the specification

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
    'Parse::CPAN::Meta 1.38',
	'Test::CPAN::Meta 0.13',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

meta_yaml_ok();

_____[ 804_manifest.t ]__________________________________________
#!perl

# Test that our MANIFEST describes the distribution

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::DistManifest 1.001003',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}
unless ( -e 'MANIFEST.SKIP' ) {
	plan( skip_all => "MANIFEST.SKIP does not exist, so cannot test this." );
}


# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

manifest_ok();

_____[ 803_minimumversion.t ]____________________________________
#!perl

# Test that our declared minimum Perl version matches our syntax

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Perl::MinimumVersion 1.20',
	'Test::MinimumVersion 0.008',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

all_minimum_version_from_metayml_ok();

_____[ 802_pod_coverage.t ]______________________________________
#!perl

# Test that modules are documented by their pod.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

# If using Moose, uncomment the appropriate lines below.
my @MODULES = (
#	'Pod::Coverage::Moose 0.01',
	'Pod::Coverage 0.20',
	'Test::Pod::Coverage 1.08',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

plan tests => 1;

pod_coverage_ok('File::List::Object', { 
#  coverage_class => 'Pod::Coverage::Moose', 
  also_private => [ qr/^[A-Z_]+$/ ],
});

_____[ 801_pod.t ]_______________________________________________
#!perl

# Test that the syntax of our POD documentation is valid

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Pod::Simple 3.08',
	'Test::Pod 1.26',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

all_pod_files_ok();

_____[ 800_perlcritic.t ]________________________________________
#!perl

# Test that modules pass perlcritic and perltidy.

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Perl::Tidy',
	'Perl::Critic',
	'Perl::Critic::Utils::Constants',
	'Perl::Critic::More',
	'Test::Perl::Critic',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "require $MODULE"; # Has to be require because we pass options to import.
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

if ( 1.099_001 > eval { $Perl::Critic::VERSION } ) {
	plan( skip_all => "Perl::Critic needs updated to 1.099_001" );
}

use File::Spec::Functions qw(catfile);
Perl::Critic::Utils::Constants->import(':profile_strictness');
my $dummy = $Perl::Critic::Utils::Constants::PROFILE_STRICTNESS_QUIET;

local $ENV{PERLTIDY} = catfile( 't', 'settings', 'perltidy.txt' );

my $rcfile = catfile( 't', 'settings', 'perlcritic.txt' );
Test::Perl::Critic->import( 
	-profile            => $rcfile, 
	-severity           => 1, 
	-profile-strictness => $Perl::Critic::Utils::Constants::PROFILE_STRICTNESS_QUIET
);
all_critic_ok();

_____[ perlcritic.txt ]__________________________________________
verbose = %f:%l:%c:\n %p: %m\n
theme = (core || more)

[ControlStructures::ProhibitPostfixControls]
allow = if unless

[RegularExpressions::RequireExtendedFormatting]
minimum_regex_length_to_complain_about = 7

[InputOutput::RequireCheckedSyscalls]
functions = :builtins
exclude_functions = print

[Modules::PerlMinimumVersion]
version = 5.008001

[ValuesAndExpressions::ProhibitMagicNumbers]
allowed_values = -1 0 1 2

# Exclusions
# I use svn - don't need the keywords.
[-Miscellanea::RequireRcsKeywords]

# I like to set up my own pod.
[-Documentation::RequirePodAtEnd]
[-Documentation::RequirePodSections]

# No Emacs!
[-Editor::RequireEmacsFileVariables]

# I need the fix in 1.099_001 for Exception::Class stuff.
[-NamingConventions::Capitalization]

# The standard versioning I'm using does not allow this.
[-ErrorHandling::RequireCheckingReturnValueOfEval]

_____[ perltidy.txt ]____________________________________________
--backup-and-modify-in-place
--warning-output
--maximum-line-length=76
--indent-columns=4
--entab-leading-whitespace=4
# --check-syntax
# -perl-syntax-check-flags=-c
--continuation-indentation=2
--outdent-long-quotes
--outdent-long-lines
--outdent-labels
--paren-tightness=1
--square-bracket-tightness=1
--block-brace-tightness=1
--space-for-semicolon
--add-semicolons
--delete-semicolons
--indent-spaced-block-comments
--minimum-space-to-comment=3
--fixed-position-side-comment=40
--closing-side-comments
--closing-side-comment-interval=12
--static-block-comments
# --static-block-comment-prefix=^#{2,}[^\s#]
--static-side-comments
--format-skipping
--cuddled-else
--no-opening-brace-on-new-line
--vertical-tightness=1
--stack-opening-tokens
--stack-closing-tokens
--maximum-fields-per-table=8
--comma-arrow-breakpoints=0
--blanks-before-comments
--blanks-before-subs
--blanks-before-blocks
--long-block-line-count=4
--maximum-consecutive-blank-lines=5

_____[ MANIFEST.SKIP ]___________________________________________

# Avoid version control files.
\bRCS\b
\bCVS\b
\bSCCS\b
,v$
\B\.svn\b
\B\.git\b
\B\.gitignore\b
\b_darcs\b

# Avoid Makemaker generated and utility files.
\bMANIFEST\.bak
\bMakefile$
\bblib/
\bMakeMaker-\d
\bpm_to_blib\.ts$
\bpm_to_blib$
\bblibdirs\.ts$         # 6.18 through 6.25 generated this

# Avoid temp and backup files.
~$
\.old$
\#$
\b\.#
\.bak$

# Avoid Devel::Cover files.
\bcover_db\b

# Avoid Module::Build generated and utility files.
\bBuild$
\bBuild.bat$
\b_build
\bBuild.COM$
\bBUILD.COM$
\bbuild.com$

# Avoid release automation.
\breleaserc$
\bMANIFEST\.SKIP$

# Avoid archives of this distribution
\b<DISTRO>-[\d\.\_]+

_____[ Module.pm ]_______________________________________________
package <MODULE NAME>;

use 5.008001;
use warnings;
use strict;
use Carp;
use English qw( -no_match_vars );

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use parent 'Parent::Class';
#  use Exception::Class 1.29 {
#  
#  };
#  use Moose;

$VERSION = '0.001';
$VERSION = eval { return $VERSION };


# Module implementation here


1; # Magic true value required at end of module
__END__

=pod

!=begin readme text

<MODULE NAME> version 0.001

!=end readme

!=for readme stop

!=head1 NAME

<MODULE NAME> - [One line description of module's purpose here]

!=head1 VERSION

This document describes <MODULE NAME> version 0.001

!=begin readme

!=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

This method of installation will install a current version of Module::Build 
if it is not already installed.
    
Alternatively, to install with Module::Build, you can use the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

!=end readme

!=for readme stop

!=head1 SYNOPSIS

    use <MODULE NAME>;

!=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exemplary as possible.

!=head1 DESCRIPTION

!=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.

!=head1 INTERFACE 

!=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

!=head1 DIAGNOSTICS

!=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

!=over

!=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

!=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

!=back

!=head1 CONFIGURATION AND ENVIRONMENT

!=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
<MODULE NAME> requires no configuration files or environment variables.

!=for readme continue

!=head1 DEPENDENCIES

!=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.

!=for readme stop

!=head1 INCOMPATIBILITIES

!=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.

!=head1 BUGS AND LIMITATIONS

!=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=<DISTRO>>
if you have an account there.

2) Email to E<lt>bug-<DISTRO>@rt.cpan.orgE<gt> if you do not.

!=head1 AUTHOR

<AUTHOR>  C<< <<EMAIL>> >>

!=for readme continue

!=head1 LICENSE AND COPYRIGHT

Copyright (c) <YEAR>, <AUTHOR> C<< <<EMAIL>> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic> and L<perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

!=for readme stop

!=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
