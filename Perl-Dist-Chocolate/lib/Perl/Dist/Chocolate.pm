package Perl::Dist::Chocolate;

=pod

=head1 NAME

Perl::Dist::Chocolate - The "Strawberry Perl Professional" distribution.

=head1 DESCRIPTION

This is the distribution builder used to create Strawberry Perl Professional 
(formerly called Chocolate Perl)

=head1 Building

Unlike Strawberry Perl, this does not have a standalone build script.

To build Strawberry Perl Professional, run the following.

  perldist Chocolate

=cut

use 5.008001;
use strict;
use warnings;
use parent                  qw( Perl::Dist::Strawberry );
use File::Spec::Functions   qw( catfile catdir         );
use File::ShareDir          qw();

our $VERSION = '2.02_02';
$VERSION =~ s/_//ms;




#####################################################################
# Configuration

# Apply some default paths
sub new {

	if ($Perl::Dist::Strawberry::VERSION < 2.1011) {
		PDWiX->throw('Perl::Dist::Strawberry version is not high enough.')
	}

	shift->SUPER::new(
		app_id            => 'chocolate',
		app_name          => 'Strawberry Perl Professional',
		app_publisher     => 'Vanilla Perl Project',
		app_publisher_url => 'http://vanillaperl.org/',
		image_dir         => 'C:\\strawberry',

		# Tasks to complete to create Chocolate
		tasklist => [
			'final_initialization',
			'initialize_using_msm',
			'install_padre_prereq_modules_1',
			'install_padre_prereq_modules_2',
			'install_padre_modules',
			'install_satori_modules_1',
			'install_satori_modules_2',
			'install_satori_modules_3',
			'install_satori_modules_4',
			'install_satori_modules_5',
			'install_satori_modules_6',
			'install_satori_modules_7',
			'install_satori_modules_8',
			'install_satori_modules_9',
			'install_satori_modules_10',
			'install_other_modules_1',
			'install_other_modules_2',
			'install_win32_extras',
			'install_chocolate_extras',
			'remove_waste',
			'create_professional_distribution_list',
			'regenerate_fragments',
			'write',
			'create_release_notes',
		],

		# Build msi and zip versions.
		msi               => 1,
		zip               => 1,

		# Perl version
		perl_version => '5101',

		# Program version.
		build_number => 3,
		beta_number  => 2,

		# Trace level.
		trace => 1,

		# Text on the exit screen
		msi_exit_text        => <<'EOT',
Before you start using Strawberry Perl Professional, read the Release Notes and the README file.  These are both available from the start menu under "Strawberry Perl Professional".
EOT
		msi_install_warning_text => q{NOTE: This version of Strawberry Perl Professional can only be installed to C:\strawberry\. If this is a problem, please download Strawberry Perl from http://strawberryperl.com/.},
		
		# These are the locations to pull down the msm.
		msm_to_use => 'http://strawberryperl.com/download/5.10.1.3/strawberry-perl-5.10.1.3-beta-2.msm',
		msm_zip    => 'http://strawberryperl.com/download/5.10.1.3/strawberry-perl-5.10.1.3-beta-2.zip',
		msm_code   => 'BC4B680E-4871-31E7-9883-3E2C74EA4F3C',
		
		@_,
	);
}

# Lazily default the file name
# Supports building multiple versions of Perl.
sub output_base_filename {
	$_[0]->{output_base_filename} or
	'strawberry-perl-professional-' . $_[0]->perl_version_human 
	. '.' . $_[0]->build_number
	. ($_[0]->beta_number ? '-alpha-' . $_[0]->beta_number : '');
}






#####################################################################
# Customisations for Perl assets

sub patch_include_path {
	my $self  = shift;

	# Find the share path for this distribution
	my $share = File::ShareDir::dist_dir('Perl-Dist-Chocolate');
	my $path  = catdir( $share, 'chocolate' );
	unless ( -d $path ) {
		PDWiX->throw("Directory $path does not exist");
	}

	# Prepend it to the default include path
	return [ $path,
		@{ $self->SUPER::patch_include_path() },
	];
}

sub install_padre_prereq_modules_1 {
	my $self = shift;

	# Manually install our non-Wx dependencies first to isolate
	# them from the Wx problems
	$self->install_modules( qw{
		  File::Glob::Windows
		  File::Next
		  App::Ack
		  Class::Adapter
		  Class::Unload
		  AutoXS::Header
		  Class::XSAccessor
		  Devel::Dumpvar
		  File::Copy::Recursive
		  File::ShareDir::PAR
		  Test::Object
		  Config::Tiny
		  Test::ClassAPI
		  Clone
		  Hook::LexWrap
		  Test::SubCalls
		  List::MoreUtils
		  PPI
		  Module::Locate
		  Perl::Tags
		  Module::Refresh
		  Devel::Symdump
		  Pod::Coverage
		  Test::Pod::Coverage
		  Test::Pod
		  Module::Starter
	} ); # 30
	$self->install_distribution(
		name             => 'ADAMK/ORLite-1.43.tar.gz',
		mod_name         => 'ORLite',
		makefilepl_param => [ 'INSTALLDIRS=vendor', ],
	);
	$self->install_modules( qw{
		  Test::Differences
		  Pod::POM
		  Parse::ErrorString::Perl
	} ); # 30

	return 1;
} ## end sub install_padre_prereq_modules_1



sub install_padre_prereq_modules_2 {
	my $self = shift;

	# NOTE: ORLite::Migrate goes after ORLite once they don't clone it privately.
	# NOTE: Test::Exception goes before Test::Most when it's not in Strawberry.
	$self->install_modules( qw{
		  Text::FindIndent
		  Pod::Abstract
		  Devel::StackTrace
		  Class::Data::Inheritable
		  Exception::Class
		  Test::Most
		  Parse::ExuberantCTags
		  CPAN::Mini
		  Capture::Tiny
		  prefork
		  Readonly
		  Readonly::XS
		  PPIx::EditorTools
		  PPIx::Regexp
		  Spiffy
		  Test::Base
		  ExtUtils::XSpp
		  Locale::Msgfmt
		  Module::ScanDeps
		  Module::Install
		  Format::Human::Bytes
		  Template::Tiny
		  Win32::Shortcut
		  Debug::Client
		  Devel::Refactor
		  App::cpanminus
		  Module::Manifest
		  POD2::Base
		  UNIVERSAL::isa
		  UNIVERSAL::can
		  Test::MockObject
	} ); # 31
	
	return 1;
} ## end sub install_padre_prereq_modules_2



sub install_padre_modules { # 4 modules
	my $self = shift;

	# Install the Alien::wxWidgets module from a precompiled .par
	my $par_url = 
		'http://strawberryperl.com/download/padre/Alien-wxWidgets-0.50-MSWin32-x86-multi-thread-5.10.1.par';
	my $filelist = $self->install_par(
		name => 'Alien_wxWidgets',
		url  => $par_url,
	);

	# Install the Wx module over the top of alien module
	$par_url = 
		'http://strawberryperl.com/download/padre/Wx-0.9701-MSWin32-x86-multi-thread-5.10.1.par';
	$filelist = $self->install_par(
		name => 'Wx',
		url  => $par_url,
	);

	# Install modules that add more Wx functionality
	$self->install_module(
		name  => 'Wx::Perl::ProcessStream',
		force => 1                     # since it fails on vista
	);

	# And finally, install Padre itself (pinned to 0.64, for now.)
#	$self->install_module(
#		name  => 'Padre',
#	);
	$self->install_distribution(
		name             => 'PLAVEN/Padre-0.64.tar.gz',
		mod_name         => 'Padre',
		makefilepl_param => [ 'INSTALLDIRS=vendor', ],
	);
	
	return 1;
} ## end sub install_padre_modules


### These modules are the ones installed by Task::Kensho 0.22,
### Task::Catalyst 4.00, and Task::Moose 0.03.


sub install_satori_modules_1 {
	my $self = shift;

	# Basic Toolchain is already installed in Strawberry, 
	# except for App::cpanminus, which Padre needs.
	
	# Testing prerequisites.
	$self->install_modules( qw{	
		PadWalker
		Devel::Cycle
		CSS::Tiny
		PPI::HTML
		AppConfig
		Template
		Perl::Tidy
	} ); # 7 (7)
	
	# Testing: Test::Simple is already installed in Strawberry.
	# Test::Exception and Test::Most are above.
	# Test::Pod and Test::Pod::Coverage are also above.
	$self->install_modules( qw{
		Test::Memory::Cycle
	} ); # 1 (8)
	$self->install_module(
		name  => 'Devel::Cover',
		force => 1,                    # One weird failure left in 0.67
	);   # 1 (9)

	# Exception Handling, part 1.
	# TryCatch needs delayed until after Moose.
	$self->install_modules( qw{
		Try::Tiny
	} ); # 1 (10)

	# Config Modules and prerequisites
	$self->install_modules( qw{
		JSON::Syck
		Config::General
		Config::Any
	} ); # 3 (13)
	
	# Date Modules prerequisites
	$self->install_modules( qw{
		Class::Singleton
		Params::Validate
		DateTime::TimeZone
		DateTime::Locale
	} ); # 4 (17)

	# Date Modules (plus MooseX::Types::DateTime/Structured)
	$self->install_modules( qw{
		DateTime
		Date::Tiny
		Time::Tiny
		DateTime::Tiny
	} ); # 4 (21)
	
	# Object Oriented Programming
		
	# Moose and prerequisites
	$self->install_modules( qw{
		Algorithm::C3
		Class::C3
		MRO::Compat
		Sub::Install
		Data::OptList
		Sub::Exporter
		Scope::Guard
		Devel::GlobalDestruction
		Sub::Name
		Package::Stash
		Class::MOP
		Moose
	} ); # 12 (33)

	return 1;
}

sub install_satori_modules_2 {
	my $self = shift;

	# Other Object Oriented Programming prereqs.
	$self->install_modules( qw{
		autobox
		Perl6::Junction
		Path::Class
		Test::use::ok
		Getopt::Long::Descriptive
		Variable::Magic
		B::Hooks::EndOfScope
		Sub::Identify
		namespace::clean
		Carp::Clan
		Set::Object
		Hash::Util::FieldHash::Compat
		Log::Log4perl
		Symbol::Util
		constant::boolean
		Test::Unit::Lite
		Exception::Base
		Test::Assert
		IO::TieCombine
		String::RewritePrefix
		App::Cmd
	} ); # 21 (21)
	
	# First part of Object Oriented Programming 
	# (MooseX::Types and MooseX::Types::Path::Class 
	#  needs to be before Test::TempDir.)
	$self->install_modules( qw{
		MooseX::Types
		MooseX::Types::Path::Class
	} ); # 2 (23)
	
	# File::NFSLock fails tests. 
	# Considering the name, should this really
	# be required by Temp::TempDir on Win32?
	$self->install_module(
		name => 'File::NFSLock',
		force => 1,
	); # 1 (24)
	# TODO: Take out YAML::XS once it's in Strawberry proper.
	$self->install_modules( qw{
		Test::TempDir
		Best
		JSON::Any
		Test::JSON
		YAML::XS
		Test::YAML::Valid
		namespace::autoclean
		URI::FromHash
		Devel::PartialDump
		Tie::ToObject
		Data::Visitor
	} ); # 11 (35)

	return 1;
}

sub install_satori_modules_3 {
	my $self = shift;

	# Main section of Object Oriented Programming 
	# MooseX::LogDispatch needs a prerequisite (Log::Dispatch::Configurator) forced.
	# MooseX::LazyLogDispatch needs a prerequisite (Log::Dispatch::Configurator) forced.
	# MooseX::POE will wait until updated for 0.90.
	# MooseX::Role::TraitConstructor is ommitted because of RT#53070. [ Perl RT#52610 ] 
	# MooseX::Role::Cmd relies on IPC::Run, which is problematic (t\parallel.t stalls).
	# MooseX::Daemonize was stalled the first time I tried it -
	#   maybe timing/OS-dependent? It also fails tests.
	$self->install_modules( qw{
		MooseX::ConfigFromFile
		MooseX::GlobRef
		MooseX::NonMoose
		Moose::Autobox
		MooseX::Aliases
		MooseX::Storage
		MooseX::Getopt
		MooseX::SimpleConfig
		MooseX::StrictConstructor
		MooseX::Traits
		MooseX::Role::Parameterized
		MooseX::Singleton
		MooseX::Types::Set::Object
		MooseX::Types::URI
		MooseX::Param
		MooseX::InsideOut
		MooseX::Clone
		MooseX::ClassAttribute
		MooseX::Iterator
		MooseX::Log::Log4perl
		MooseX::App::Cmd
		MooseX::Meta::TypeConstraint::ForceCoercion
		MooseX::Object::Pluggable
		MooseX::Types::DateTime
		MooseX::Types::Structured
		Pod::Coverage::Moose
	} ); # 26 (26)

	# TryCatch prerequisites
	$self->install_modules( qw{
		aliased
		Parse::Method::Signatures
		Scope::Upper
		ExtUtils::Depends
		B::Hooks::OP::Check
		B::Hooks::OP::PPAddr
		Devel::Declare
	} ); # 7 (33)

	return 1;
}
	
sub install_satori_modules_4 {
	my $self = shift;

	# Last part of OOP.
	$self->install_modules( qw{
		Context::Preserve
		MooseX::LazyRequire
		MooseX::Method::Signatures
		MooseX::Declare
	} ); # 4 (4)

	# Exception Handling, part 2.
	$self->install_modules( qw{
		TryCatch
	} ); # 1 (5)

	# XML development prerequisites
	$self->install_modules( qw{
		XML::Filter::BufferText
		Text::Iconv
	} ); # 2 (7)

	# XML Development: XML::LibXML and XML::SAX are already installed.
	$self->install_modules( qw{
		XML::Generator::PerlData
		XML::SAX::Writer
	} ); # 2 (9)
	
	# Module Development prerequisites
	$self->install_modules( qw{
		Regexp::Common
		Pod::Readme
		Data::Section
		Text::Template
		Software::License
		B::Keywords
		String::Format
		Email::Address
		Pod::Spell
		Regexp::Parser
		Mixin::Linewise::Readers
		Tie::IxHash
		Config::MVP
		Config::INI
		Config::MVP::Reader::INI
		Pod::Eventual
		String::Flogger
		Mixin::ExtraFields
		Mixin::ExtraFields::Param
		Hash::Merge::Simple
		String::Formatter
		File::ShareDir::Install
		File::chdir
		Sub::Exporter::ForMethods
		String::Truncate
		Pod::Elemental
		Sys::Syslog
		Log::Dispatch
		Log::Dispatch::Array
		Log::Dispatchouli
		Pod::Weaver
		Pod::Elemental::PerlMunger
	} );  # 32 (41)
	
	return 1;
}

sub install_satori_modules_5 {
	my $self = shift;

	# More prereqs for Module Development
	$self->install_modules( qw{
		MooseX::Types::Perl
		MooseX::SetOnce
		Version::Requirements
		CPAN::Meta
		Perl::PrereqScanner
		PPIx::Utilities
	} );  # 6 (6)
	
	# Module Development
	$self->install_modules( qw{
		CPAN::Uploader
		Perl::Version
		Dist::Zilla
		Dist::Zilla::Plugin::PodWeaver
		Perl::Critic
		Perl::Critic::More
		Carp::Always
		Modern::Perl
	} ); # 8 (14)
	$self->install_module(
		name => 'Devel::NYTProf',
		force => 1,
	); # 1 (15)

	# Database Development: DBI and DBD::SQLite are already installed.
	# Because of the large numbers of prerequisites, I'm
	# doing this one module at a time.
	
	# DBIx::Class and prerequisites.
	$self->install_modules( qw{
		Class::Accessor::Grouped
		SQL::Abstract
		SQL::Abstract::Limit
		Class::Accessor
		Class::Accessor::Chained::Fast
		Data::Page
		Class::C3::Componentised
		Module::Find
		Devel::ArgNames
	} ); # 11 (26)
	# The 2.000 version of DDC makes DBIx::Class::Schema::Loader fail tests.
	$self->install_distribution(
		name             => 'MSTROUT/Data-Dumper-Concise-1.200.tar.gz',
		mod_name         => 'Data::Dumper::Concise',
		makefilepl_param => [ 'INSTALLDIRS=vendor', ],
	);
	$self->install_modules( qw{
		Math::Base36
		DBIx::Class
	} ); # 11 (26)
	
	# SQL::Translator and prerequisites
	$self->install_modules( qw{
		Class::Base
		Parse::RecDescent
		Class::MakeMethods
		XML::Writer
		SQL::Translator
	} ); # 5 (31)

	# DBIx::Class::Schema::Loader and prereqs
	# Note: DBD::Oracle and DBD::DB2 you're 
	# on your own for.
	$self->install_modules( qw{
		Lingua::EN::Inflect
		Lingua::EN::Inflect::Number
		Class::Data::Accessor
		UNIVERSAL::require
		Data::Dump
		Lingua::Stem::Ru
		Lingua::Stem::Fr
		Lingua::Stem::It
		Lingua::Stem::Snowball::Da
		Lingua::Stem::Snowball::Se
		Lingua::Stem::Snowball::No
		Lingua::PT::Stemmer
		Text::German
		Lingua::Stem
		Memoize::ExpireLRU
		Lingua::EN::Tagger
		Lingua::EN::Inflect::Phrase
		DBIx::Class::Schema::Loader
	} ); # 18 (49)

	return 1;
}

sub install_satori_modules_6 {
	my $self = shift;

	# Excel/CSV
	$self->install_modules( qw{
		Text::CSV_XS
		OLE::Storage_Lite
		Spreadsheet::ParseExcel
		Spreadsheet::WriteExcel
		Spreadsheet::ParseExcel::Simple
		Spreadsheet::WriteExcel::Simple
	} ); # 6 (6)
	
	# Adding DBD's to the list.
	$self->install_distribution(
		name             => 'REHSACK/SQL-Statement-1.27.tar.gz',
		mod_name         => 'SQL::Statement',
		makefilepl_param => [ 'INSTALLDIRS=vendor', ],
	);
	$self->install_modules( qw{
		DBD::CSV
		DBD::Excel
	} ); # 3 (9)

	# Web Development

	# Catalyst::Runtime and prerequisites
	$self->install_modules( qw{
		Text::SimpleTable
		Class::C3::Adopt::NEXT
		MooseX::MethodAttributes::Inheritable
		HTTP::Request::AsCGI
		Tree::Simple
		Tree::Simple::Visitor::FindByPath
		CGI::Simple::Cookie
		HTTP::Body
		MooseX::Emulate::Class::Accessor::Fast
		MooseX::Role::WithOverloading
		MooseX::Types::Common
		Catalyst::Runtime
	} ); # 12 (21)

	# Catalyst::Devel and prerequisites
	$self->install_modules( qw{
		MIME::Types
		Catalyst::Plugin::Static::Simple
		Devel::Caller
		MooseX::Params::Validate
		MooseX::SemiAffordanceAccessor
		File::ChangeNotify
		Catalyst::Action::RenderView
		Test::Requires
		Mouse
		Any::Moose
		Catalyst::Plugin::ConfigLoader
		Proc::Background
		Catalyst::Devel
	} ); # 13 (34)

	return 1;
}

sub install_satori_modules_7 {
	my $self = shift;

	# Prerequisites for the rest of web development
	$self->install_modules( qw{
		Template::Timer
		MooseX::Traits::Pluggable
		CatalystX::Component::Traits
		Error
		Cache::FileCache
		DBIx::Class::Cursor::Cached
		Hash::Merge
		Object::Signature
		URI::Find
		Sub::Override
		HTML::TokeParser::Simple
		Locale::Maketext::Lexicon
		Regexp::Assemble
		Log::Trace
		Test::Assertions
		Hash::Flatten
		Regexp::Copy
		HTML::Tiny
		Captcha::reCAPTCHA
		Bit::Vector
	} ); # 20 (20)

	$self->install_modules( qw{
		Date::Calc
		HTML::Scrubber
		Class::Factory::Util
		DateTime::Format::Strptime
		DateTime::Format::Builder
		HTML::FillInForm
		Test::MockTime
		boolean
		DateTime::Format::Natural
		Class::Throwable
		HTML::Template
		CGI::FastTemplate
		CGI::FormBuilder
		Carp::Assert
		Carp::Assert::More
		Test::LongString
		DateTime::Format::W3CDTF
		DateTime::Format::Mail
		XML::XPath
		Number::Format
	} ); # 20 (40)

	return 1;
}
	
sub install_satori_modules_8 {
	my $self = shift;

	# More web development prerequisites
	$self->install_modules( qw{
		HTML::TreeBuilder
		MooseX::RelatedClassRoles
		Data::Serializer
		Data::Taxi
		Data::Stream::Bulk
		BerkeleyDB::Manager
	} ); # 6 (6)
	
	# For Catalyst::View::Email
	$self->install_modules( qw{
		Throwable::Error
		Email::Date::Format
		Email::Simple
		Email::Abstract
	} );
	# This module requires a network connection to test correctly.
	$self->install_module( name => 'Sys::Hostname::Long', force => $self->offline(), );
	$self->install_modules( qw{
		Email::Sender::Simple
		Authen::SASL
		Email::MIME::Encodings
		Email::MIME::ContentType
		Email::MessageID
		Email::MIME
	} ); # 11 (17)

	# Most of the rest of Web Development
	$self->install_modules( qw{
		Catalyst::Engine::Apache
		Catalyst::Log::Log4perl
		Catalyst::View::TT
		Catalyst::View::JSON
		Catalyst::Model::Adaptor
		Catalyst::Model::DBIC::Schema
		Catalyst::Controller::ActionRole
		Catalyst::Action::REST
		Catalyst::Plugin::Session
		Catalyst::Plugin::Authentication
		Catalyst::Plugin::StackTrace
		Catalyst::Plugin::FillInForm
		Catalyst::Plugin::I18N
		Catalyst::Plugin::Compress::Zlib
		Catalyst::Plugin::Session::State::Cookie
		Catalyst::Plugin::Session::Store::File
		Catalyst::Plugin::Session::Store::Delegate
		Catalyst::Plugin::Session::Store::DBIC
		Catalyst::Plugin::Session::State::URI
		Catalyst::Plugin::Authorization::Roles
		CatalystX::InjectComponent
		Catalyst::ActionRole::ACL
	} ); # 22 (39)

	return 1;
}
	
sub install_satori_modules_9 {
	my $self = shift;

	# Web Crawling and prereqs: LWP::Simple and everything 
	# in Bundle::LWP are already installed.
	# WWW::Mechanize is forced because the back test fails on the 
	# '404 check' test if the firewall is too severe.
	$self->install_modules( qw{
		HTTP::Server::Simple
		HTTP::Lite
	} ); # 2 (2)
		
	$self->install_module( name => 'WWW::Mechanize', force => 1, );
	$self->install_module( name => 'Test::WWW::Mechanize', force => 1, );
	$self->install_module( name => 'WWW::Mechanize::TreeBuilder', force => 1, );
	# 3 (5)

	# In Web Devel, but needed a prereq first.
	$self->install_module( name => 'Test::WWW::Mechanize::Catalyst', force => 1, );
	# 1 (6)
	
	# More of web development (C::P::S::S::BDB and C::P::A::ACL requires 
	# Test::WWW::Mech::Cat, and may need forced.)
	# CPSS::BDB needs forced because if the temp directory is not clear, the tests break.
	$self->install_module( name => 'Catalyst::Plugin::Session::Store::BerkeleyDB', force => 1, );
	$self->install_modules( qw{
		Catalyst::Plugin::Authorization::ACL
		Catalyst::Component::InstancePerContext
		Catalyst::Authentication::Store::DBIx::Class
	} ); # 4 (10)

	# Could not install FCGI::ProcManager due to POSIX error.
	# (MIME::Types was needed for Catalyst::Devel.)
	$self->install_modules( qw{
		CGI::FormBuilder::Source::Perl
		XML::RSS
		XML::Atom
	} ); # 3 (13)

	# E-mail Modules prerequisites
	$self->install_modules( qw{
		IO::CaptureOutput
		Net::SMTP::SSL
		File::Find::Rule::Perl
	} );
	# Hard-coding to 1.26 for now. 
	# The minicpan has it, but it wasn't in the indexes yet.
	$self->install_distribution(
		name             => 'ADAMK/Perl-MinimumVersion-1.26.tar.gz',
		mod_name         => 'Perl::MinimumVersion',
		makefilepl_param => [ 'INSTALLDIRS=vendor', ],
	);
	$self->install_modules( qw{
		Test::MinimumVersion
		Date::Format
		Mail::Address
	} ); # 7 (20)

	# E-mail Modules (Email::Simple was earlier.)
	$self->install_modules( qw{
		Email::Valid
	} ); # 1 (21)

	# Localizing changes to environment for building purposes.
	{
		local $ENV{TZ} = 'PST8PDT';
		$self->install_module( name => 'Time::ParseDate' );
	} # 1 (23)
	
	# Almost the last of Web Development
	# (HTML::FormFu and HTML::FormHandler requires the Email:: stuff.)
	# HTML::FormFu 0.07002 also has a test bug. (reported as RT#59467)
	$self->install_module( name => 'HTML::FormFu', force => 1 );
	$self->install_modules( qw{
		Catalyst::Controller::HTML::FormFu
		HTML::FormHandler
		CatalystX::SimpleLogin
		CatalystX::LeakChecker
		CatalystX::Profile
		String::Escape
		Data::UUID
		Catalyst::Authentication::Credential::HTTP
		CGI::Cookie::XS
		Cookie::XS
	} ); # 11 (34)

	# Net::Server 0.99 has problems. Using 0.97 instead.
	$self->install_distribution(
		name             => 'RHANDOM/Net-Server-0.97.tar.gz',
		mod_name         => 'Net::Server',
		makefilepl_param => [ 'INSTALLDIRS=vendor', ],
	);
	# HTTP::HeaderParser::XS does not link in 5.10 (works on 5.12 64-bit.)
	# Catalyst::Engine::HTTP::Prefork requires module above that does not link.
	$self->install_modules( qw{
		Test::SharedFork
		Test::TCP
		Catalyst::Engine::PSGI
		Catalyst::Plugin::Unicode::Encoding
		Catalyst::View::Email
		Catalyst::Manual
	} ); # 6 (40)

	# Useful Command-line Tools prerequisites
	$self->install_modules( qw{
		B::Utils
		Data::Dump::Streamer
		Devel::LexAlias
		Lexical::Persistence
		WWW::Pastebin::PastebinCom::Create
		Win32::Clipboard
		Clipboard
		App::Nopaste
	} ); # 8 (48)

	return 1;
}
	
sub install_satori_modules_10 {
	my $self = shift;
	
    # Needed for Devel::REPL and MooseX::POE.
	# I consider the fact that this needs installed
	# at all a bug.
	$self->install_modules( qw{
		MooseX::AttributeHelpers
	} ); # 1 (1)
	
	# Useful Command-line Tools: Module::CoreList is 
	# already installed by Strawberry, and App::Ack 
	# is above. App::perlbrew is Unix-specific.
	$self->install_modules( qw{
		Devel::REPL
	} ); # 1 (2)

	# CatalystX::REPL needs Devel::REPL, and since Carp::REPL 
	# and CatalystX::REPL use Expect for tests, we have to force them.
	$self->install_module( name => 'Devel::StackTrace::WithLexicals' );
	$self->install_module( name => 'Carp::REPL', force => 1 );
	$self->install_module( name => 'CatalystX::REPL', force => 1 );
	$self->install_module( name => 'Task::Catalyst' ); # 4 (6)
		
	# Script Hackery prerequisites
	# These 2 have a signature test, which fails atm.
	$self->install_module( name => 'Class::MethodMaker', force => 1, );
	$self->install_module( name => 'Term::ProgressBar', force => 1, );
	$self->install_modules( qw{
		File::ReadBackwards
		MLDBM
		Term::ProgressBar::Quiet
	} ); # 5 (11)

	# Script Hackery
	$self->install_modules( qw{
		Smart::Comments
		Term::ProgressBar::Simple
		IO::All
	} ); # 3 (15)
	
	# Asynchronous Programming and prerequisites
	$self->install_modules( qw{
		Win32::Console
		Win32::Job
		POE::Test::Loops
		POE
	} ); # 4 (19)


	# These OO module(s) requires POE.
	# MooseX::Workers fails tests. Reported in (by another) to CPAN Testers as 
	# http://www.cpantesters.org/cpan/report/06928127-b19f-3f77-b713-d32bba55d77f.
	$self->install_modules( qw{
		MooseX::Async
		MooseX::POE
	} ); # 2 (21)

	# Scalability: CHI and prereqs (added in Task::Kensho 0.23)
	$self->install_modules( qw{
		Hash::MoreUtils
		Log::Any
		Log::Any::Adapter
		Log::Any::Adapter::Dispatch
		Test::Log::Dispatch
		Exporter::Lite
		Time::Duration
		Time::Duration::Parse
		Digest::JHash
		Test::Class
		CHI
	} ); # 11 (32)

	# Final tasks
	$self->install_modules( qw{
		Task::Moose
		Task::Kensho
	} ); # 2 (34)

	return 1;
}

sub install_other_modules_1 {
	my $self = shift;

	# Install the Tk module from a precompiled .par
	my $par_url = 
		'http://strawberryperl.com/download/professional/Tk-804.028502-MSWin32-x86-multi-thread-5.10.1.par';
	my $filelist = $self->install_par(
		name => 'Tk',
		url  => $par_url,
	);
	
	$self->install_module(
		name  => 'Win32::GUI',
		force => 1,   # Fails a pod test.
	); # 2 (2)
	
	# Tkx needs Tcl, which needs a 'tclsh' binary.
	# Gtk2 requires binaries

	# CPAN helper. We need a better one.
	$self->install_modules( qw{
		CPANPLUS::Shell::Wx		
	} ); # 1 (3)

	# Pod Browser.
	$self->install_modules( qw{
		Tk::Pod		
	} ); # 1 (6 - 2)
	
	# BioPerl and as many of its optionals as possible.
	# GraphViz is a known problem - Alpha 3?	
	$self->install_modules( qw{
		Data::Stag
	} );
	# This module requires a network connection to test correctly.
	$self->install_module( name => 'Ace', force => $self->offline(), );
	$self->install_modules( qw{
		Math::Random
		Math::Derivative
		SVG
		Graph
		Math::Spline
	} ); # 7 (13)
		
	$self->install_module(
		name  => 'Statistics::Descriptive',
		force => 1,   # Fails a test OCCASIONALLY.
	); # 1 (14)

	$self->install_modules( qw{
		SVG::Graph
		Algorithm::Munkres
		XML::Parser::PerlSAX
		XML::RegExp
		XML::DOM
		XML::XPathEngine
		XML::DOM::XPath
		XML::Twig
		PostScript::TextBlock
		Array::Compare
		Convert::Binary::C
		Set::Scalar
	} ); # 13 (27)

	$self->install_module(
		name  => 'Bio::Perl',
		assume_installed => 1,   # CPAN can't verify whether it's up to date once successfully installed.
	); # 1 (28)

	# Add a file that ends up missing.
	$self->add_to_fragment('Bio_Perl', [ $self->file(qw(perl bin bp_pg_bulk_load_gff.pl)) ] );

	# This makes a circular dependency if I put it before Bio::Perl.
	$self->install_modules( qw{
		Bio::ASN1::EntrezGene
	} ); # 1 (29)

	# Padre Plugins.
	$self->install_modules( qw{
		Padre::Plugin::PerlTidy
		Padre::Plugin::PerlCritic
		Padre::Plugin::Catalyst
	} ); # 3 (32)

	# Perl::Shell and prereqs.
	$self->install_modules( qw{
		Perl::Shell
	} ); # 1 (33)
	
	# Colorize the CPAN shell.
	$self->install_modules( qw{
		Win32::Pipe
		Win32::Console::ANSI
	} ); # 2 (35)
	
	# Plack & PSGI (may be removed later)
#	$self->install_modules( qw{
#		Pod::Usage
#		Devel::StackTrace::AsHTML
#		Filesys::Notify::Simple
#		Test::TCP
#		Test::Requires
#		PSGI
#		CGI::PSGI
#		CGI::Emulate::PSGI
#		Plack
#		HTTP::Server::Simple::PSGI
#		HTTP::Parser::XS
#	} );

	# Plack::Server::ReverseHTTP
	# Plack::Request
	# Parallel::Prefork
	# FCGI::Client
	# FCGI::ProcManager
	# Sys::Sendfile
	# Devel::StackTrace::WithLexicals
	# Task::Plack
	# Plack::Server::POE
	
	return 1;
}

sub install_other_modules_2 {
	my $self = shift;

	# Install some games.
	$self->install_modules( qw{
		Text::Patch
		Tie::Simple
	} ); # 1 (1)
	
	# Install the Alien::SDL module from a precompiled .par
	my $par_url = 
		'http://strawberryperl.com/download/professional/Alien-SDL-1.410-MSWin32-x86-multi-thread-5.10.1.par';
	my $filelist = $self->install_par(
		name => 'Alien_SDL',
		url  => $par_url,
	); # 1 (2)
	
	$self->install_distribution(
		name             => 'KTHAKORE/SDL-2.502.tar.gz',
		mod_name         => 'SDL',
		makefilepl_param => [ 'INSTALLDIRS=vendor', ],
	);
	$self->install_modules( qw{
		Games::FrozenBubble
	} ); # 2 (4)

	# Install CPAN Testers 2.0 stuff.
	$self->install_modules( qw{
		Data::GUID
		Metabase::Fact
		Metabase::Client::Simple
		Test::Reporter
		CPAN::Testers::Report
		Config::Perl::V
		Test::Reporter::Transport::Metabase
		Devel::Autoflush
		Tee
		CPAN::Reporter
	} ); # 10 (14)
	
	return 1;
}

sub install_chocolate_extras {
	my $self = shift;

	my $sb_dist_dir = File::ShareDir::dist_dir('Perl-Dist-Strawberry');
	my $dist_dir = File::ShareDir::dist_dir('Perl-Dist-Chocolate');
	
	# Links to the Strawberry Perl website.
	# Don't include this for non-Strawberry sub-classes
	if ( ref($self) eq 'Perl::Dist::Chocolate' ) {
		$self->patch_file( 'README.professional.txt' => $self->image_dir(), { dist => $self } );

		$self->install_launcher(
			name => 'Check installed versions of modules',
			bin  => 'module-version',
		);
		$self->install_launcher(
			name => 'Create local library areas',
			bin  => 'llw32helper',
		);

		$self->add_icon(
			name         => 'Strawberry Perl Professional README',
			directory_id => 'D_App_Menu',
			filename     => $self->image_dir()->file('README.professional.txt')->stringify(),
		);
			
		$self->install_website(
			name       => 'Strawberry Perl Website',
			url        => $self->strawberry_url(),
			icon_file  => catfile($sb_dist_dir, 'strawberry.ico'),
		);
		
		$self->install_website(
			name         => 'Strawberry Perl Professional Release Notes',
			url          => $self->chocolate_release_notes_url(),
			icon_file    => catfile($dist_dir, 'chocolate.ico'),
			directory_id => 'D_App_Menu',
		);
		
		# Link to IRC.
		$self->install_website(
			name       => 'Live Support',
			url        => 'http://widget.mibbit.com/?server=irc.perl.org&channel=%23win32',
			icon_file  => catfile($sb_dist_dir, 'onion.ico')
		);		
	}

	# Check that the padre.exe exists
	my $to = catfile( $self->image_dir(), 'perl', 'bin', 'padre.exe' );
	if ( not -f $to ) {
		PDWiX->throw(q{The "padre.exe" file does not exist});
	}

	# Get the Id for directory object that stores the filename passed in.
	my $dir_id = $self->get_directory_tree()->search_dir(
		path_to_find => catdir( $self->image_dir(), 'perl', 'bin' ),
		exact        => 1,
		descend      => 1,
	)->get_id();

	my $padre_icon_id =
	  $self->_icons()
	  ->add_icon( catfile( $dist_dir, 'padre.ico' ), 'padre.exe' );

	# Add the start menu icon.
	$self->get_fragment_object('StartMenuIcons')->add_shortcut(
		name => 'Padre',
		description =>
'Perl Application Development and Refactoring Environment - a Perl IDE',
		target      => "[D_$dir_id]padre.exe",
		id          => 'Padre',
		working_dir => $dir_id,
		icon_id     => $padre_icon_id,
		directory_id => 'D_App_Menu_Tools',
	);

	$self->install_launcher(
		name => 'Graphical CPAN Client (needs work)',
		bin  => 'wxcpan',
	);

	$self->install_launcher(
		name => 'Graphical Documentation Browser',
		bin  => 'tkpod',
	);

	$self->install_launcher(
		name => 'Perl Shell',
		bin  => 'perlcmd',
	);

	$self->install_launcher(
		name => 'Devel-REPL Shell',
		bin  => 're',
	);
	
	my $app_menu = $self->get_directory_tree()->get_directory_object('D_App_Menu');
	$app_menu->add_directories_id('App_Menu_Games', 'Games in Perl');
	
	$self->install_launcher(
		name         => 'Frozen Bubble',
		bin          => 'frozen-bubble',
		directory_id => 'D_App_Menu_Games',
	);
	
	$self->install_website(
		name       => 'Catalyst Web Framework',
		url        => 'http://www.catalystframework.org/',
		icon_file  => catfile($dist_dir, 'catalyst.ico')
	);
	
	$self->install_website(
		name       => 'Moose - Object Orientation for Perl',
		url        => 'http://moose.perl.org/',
		icon_file  => catfile($dist_dir, 'chocolate.ico')
	);
	
	$self->install_website(
		name       => 'BioPerl wiki',
		url        => 'http://www.bioperl.org/wiki/Main_Page',
		icon_file  => catfile($dist_dir, 'chocolate.ico')
	);

	$self->install_website(
		name       => 'Information about learning Perl',
		url        => 'http://learn.perl.org/',
		icon_file  => catfile($sb_dist_dir, 'perlhelp.ico')
	);

	$self->install_website(
		name       => 'Beginning Perl book',
		url        => 'http://learn.perl.org/books/beginning-perl/',
		icon_file  => catfile($sb_dist_dir, 'perlhelp.ico')
	);
	
	my $license_file_from = catfile($sb_dist_dir, 'License.rtf');
	my $license_file_to = catfile($self->license_dir(), 'License.rtf');
	my $readme_file = $self->file('README.professional.txt');
	my $dists_file = $self->file('DISTRIBUTIONS.txt');

	$self->copy_file($license_file_from, $license_file_to);	
	$self->add_to_fragment( 'Win32Extras',
		[ $license_file_to, $readme_file, $dists_file ] );
	
	return 1;
}


sub strawberry_url {
	my $self = shift;
	my $path = $self->output_base_filename();

	# Strip off anything post-version
	unless ( $path =~ s/^(strawberry-perl-professional-\d+(?:\.\d+)+).*$/$1/ ) {
		PDWiX->throw("Failed to generate the strawberry subpath");
	}

	return "http://strawberryperl.com/$path";
}


sub release_notes_filename {
	my $self = shift;
	my $filename =
	    $self->perl_version_human() . q{.}
	  . $self->build_number()
	  . ( $self->beta_number() ? '.alpha.' . $self->beta_number() : q{} )
	  . '.professional.html';

	return $filename;
}

sub chocolate_release_notes_url {
	my $self = shift;
	my $path = $self->perl_version_human()
		. q{.} . $self->build_number()
		. ($self->beta_number() ? '.alpha.' . $self->beta_number() : '')
        . '.professional';
	return "http://strawberryperl.com/release-notes/$path.html";
}


sub create_professional_distribution_list {
	my $self = shift;
	
	$self->create_distribution_list_file('DISTRIBUTIONS.professional.txt');
}


sub dist_dir {
	return File::ShareDir::dist_dir('Perl-Dist-Chocolate');
}

sub msi_fileid_readme_txt {
	my $self = shift;

	# Set the fileid attributes.
	my $readme_id =
	  $self->get_fragment_object('Win32Extras')
	  ->find_file_id( $self->file(qw(README.professional.txt)) );
	if ( not $readme_id ) {
		PDWiX->throw("Could not find README.professional.txt's ID.\n");
	}

	return $readme_id;

} ## end sub msi_fileid_readme_txt

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Chocolate>

Please note that B<only> bugs in the distribution itself or the CPAN
configuration should be reported to RT. Bugs in individual modules
should be reported to their respective distributions.

For more support information and places for discussion, see the
Strawberry Perl Support page L<http://strawberryperl.com/support.html>.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.  

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
