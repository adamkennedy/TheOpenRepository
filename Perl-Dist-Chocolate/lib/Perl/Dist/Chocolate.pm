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

our $VERSION = '2.03';
$VERSION = eval $VERSION;





#####################################################################
# Configuration

# Apply some default paths
sub new {

	if ($Perl::Dist::Strawberry::VERSION < 2.0201) {
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
			'install_strawberry_modules_5',   # Remove when using final MSM for April.
			'install_padre_prereq_modules_1',
			'install_padre_prereq_modules_2',
			'install_padre_modules',
			'install_satori_modules_1',
			'install_satori_modules_2',
			'install_satori_modules_3',
			'install_satori_modules_4',
			'install_other_modules_1',
			'install_win32_extras',
			'install_strawberry_extras',
			'install_chocolate_extras',
			'remove_waste',
			'add_forgotten_files',
			'create_distribution_list',
			'regenerate_fragments',
			'write',
		],

		# Build msi and zip versions.
		msi               => 1,
		zip               => 1,

		# Perl version
		perl_version => '5101',

		# Program version.
		build_number => 2,
		beta_number  => 1,

		# Trace level.
		trace => 1,

		# These are the locations to pull down the msm.
		msm_to_use => 'http://strawberryperl.com/download/strawberry-msm/strawberry-perl-5.10.1.1.msm',
		msm_zip    => 'http://strawberryperl.com/download/strawberry-perl-5.10.1.1.zip',
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
		@{ $self->SUPER::patch_include_path },
	];
}

sub install_padre_prereq_modules_1 { # 27 modules
	my $self = shift;

	$self->{force} = 1;
	
	# Manually install our non-Wx dependencies first to isolate
	# them from the Wx problems
	$self->install_modules( qw{
		  File::Glob::Windows
		  File::Next
		  App::Ack
		  Class::Adapter
		  Class::Inspector
		  Class::Unload
		  AutoXS::Header
		  Class::XSAccessor
		  Devel::Dumpvar
		  File::Copy::Recursive
		  File::ShareDir
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
	} );

	return 1;
} ## end sub install_padre_prereq_modules_1



sub install_padre_prereq_modules_2 { # 28 modules
	my $self = shift;

	# NOTE: ORLite::Migrate goes after ORLite once they don't clone it privately.
	# NOTE: Test::Exception goes before Test::Most when it's not in Strawberry.
	$self->install_modules( qw{
		  Module::Starter
		  ORLite
		  Test::Differences
		  File::Slurp
		  Pod::POM
		  Parse::ErrorString::Perl
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
		  PPIx::EditorTools
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
	} );
	
	return 1;
} ## end sub install_padre_prereq_modules_2



sub install_padre_modules { # 4 modules
	my $self = shift;

	# The rest of the modules are order-specific,
	# for reasons maybe involving CPAN.pm but not fully understood.

	# Install the Alien::wxWidgets module from a precompiled .par
	my $par_url = 
		'http://strawberryperl.com/download/padre/Alien-wxWidgets-0.50-MSWin32-x86-multi-thread-5.10.1.par';
	my $filelist = $self->install_par(
		name => 'Alien_wxWidgets',
		url  => $par_url,
	);

	# Install the Wx module over the top of alien module
	$self->install_module( name => 'Wx' );

	# Install modules that add more Wx functionality
	$self->install_module(
		name  => 'Wx::Perl::ProcessStream',
		force => 1                     # since it fails on vista
	);

	# And finally, install Padre itself
	$self->install_module(
		name  => 'Padre',
#		force => 1,
	);
	
	return 1;
} ## end sub install_padre_modules

sub install_satori_modules_1 {
	my $self = shift;

	# Basic Toolchain is already installed in Strawberry.
	
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
		Devel::Cover
	} ); # 2 (9)

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
		Class::MOP
		Moose
	} ); # 11 (24)
	
	# Other Object Oriented Programming prereqs.
	$self->install_modules( qw{
		autobox
		Perl6::Junction
		Path::Class
		Test::use::ok
		Params::Validate
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
		App::Cmd
	} ); # 21 (45)
	
	# First part of Object Oriented Programming 
	# (MooseX::Types and MooseX::Types::Path::Class 
	#  needs to be before Test::TempDir.)
	$self->install_modules( qw{
		MooseX::Types
		MooseX::Types::Path::Class
	} ); # 2 (47)
	
	# More Object Oriented Programming prereqs.

	# File::NFSLock fails tests. 
	# Considering the name, should this really
	# be required by Temp::TempDir on Win32?
	$self->install_module(
		name => 'File::NFSLock',
		force => 1,
	); # 1 (48)
	$self->install_modules( qw{
		Test::TempDir
		Best
		JSON::Any
		Test::JSON
		YAML::XS
		Test::YAML::Valid
		namespace::autoclean
		String::RewritePrefix
		URI::FromHash
		Devel::PartialDump
		Tie::ToObject
		Data::Visitor
	} ); # 12 (60)
	
	# Main section of Object Oriented Programming 
	# MooseX::LogDispatch needs a prerequisite (Log::Dispatch::Configurator) forced.
	# MooseX::LazyLogDispatch needs a prerequisite (Log::Dispatch::Configurator) forced.
	# MooseX::POE will wait until updated for 0.90.
	# MooseX::Workers will wait until updated for 0.90.
	# MooseX::Role::TraitConstructor is ommitted because of RT#53070.
	# MooseX::Role::Cmd relies on IPC::Run, which is problematic (t\parallel.t stalls).
	# MooseX::Daemonize was stalled the first time I tried it -
	#   maybe timing/OS-dependent?
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
		MooseX::Types::Structured
		MooseX::Types::URI
		MooseX::Param
		MooseX::InsideOut
		MooseX::Clone
		MooseX::ClassAttribute
		MooseX::Iterator
		MooseX::Log::Log4perl
		MooseX::App::Cmd
		MooseX::Meta::TypeConstraint::ForceCoercion
		Pod::Coverage::Moose
	} ); # 24 (84)

	return 1;
}
	
sub install_satori_modules_2 {
	my $self = shift;

	# TryCatch prerequisites
	$self->install_modules( qw{
		aliased
		Parse::Method::Signatures
		Scope::Upper
		ExtUtils::Depends
		B::Hooks::OP::Check
		B::Hooks::OP::PPAddr
		Devel::Declare
	} ); # 7 (7)

	# Last part of OOP.
	$self->install_modules( qw{
		Context::Preserve
		MooseX::LazyRequire
		MooseX::Method::Signatures
		MooseX::Declare
	} ); # 4 (11)

	# Exception Handling, part 2.
	$self->install_modules( qw{
		TryCatch
	} ); # 1 (12)

	# XML development prerequisites
	$self->install_modules( qw{
		XML::Filter::BufferText
		Text::Iconv
	} ); # 2 (14)

	# XML Development: XML::LibXML and XML::SAX are already installed.
	$self->install_modules( qw{
		XML::Generator::PerlData
		XML::SAX::Writer
	} ); # 2 (16)

	# Date Modules prerequisites
	$self->install_modules( qw{
		Class::Singleton
		DateTime::TimeZone
		DateTime::Locale
	} ); # 3 (19)

	# Date Modules (plus MooseX::Types::DateTime)
	$self->install_modules( qw{
		DateTime
		MooseX::Types::DateTime
		Date::Tiny
		Time::Tiny
		DateTime::Tiny
	} ); # 5 (24)
	
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
		Readonly
		Readonly::XS
		Regexp::Parser
		Mixin::Linewise::Readers
		Tie::IxHash
		Config::MVP
		Config::INI
		Config::INI::MVP::Reader
		Pod::Eventual
		String::Flogger
		Mixin::ExtraFields
		Mixin::ExtraFields::Param
		CPAN::Uploader
		Hash::Merge::Simple
		String::Formatter
		File::ShareDir::Install
		File::chdir
	} );  # 29 (53)
	
	# Module Development
	$self->install_modules( qw{
		Perl::Version
		Dist::Zilla
		Module::Install
		Perl::Critic
		Perl::Critic::More
		Carp::Always
		Modern::Perl
	} ); # 7 (60)
	$self->install_module(
		name => 'Devel::NYTProf',
		force => 1,
	); # 1 (61)

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
		Data::Dumper::Concise
		DBIx::Class
	} ); # 11 (72)

	return 1;
}

sub install_satori_modules_3 {
	my $self = shift;

	# SQL::Translator and prerequisites
	$self->install_modules( qw{
		Class::Base
		Parse::RecDescent
		Class::MakeMethods
		XML::Writer
		File::ShareDir
		SQL::Translator
	} ); # 6 (6)

	# DBIx::Class::Schema::Loader and prereqs
	# Note: DBD::Oracle and DBD::DB2 you're 
	# on your own for.
	$self->install_modules( qw{
		Lingua::EN::Inflect
		Lingua::EN::Inflect::Number
		Class::Data::Accessor
		UNIVERSAL::require
		Data::Dump
		DBIx::Class::Schema::Loader
	} ); # 6 (12)

	# Excel/CSV
	$self->install_modules( qw{
		Text::CSV_XS
		OLE::Storage_Lite
		Spreadsheet::ParseExcel
		Spreadsheet::WriteExcel
		Spreadsheet::ParseExcel::Simple
		Spreadsheet::WriteExcel::Simple
	} ); # 3 (15)
		
	# Adding DBD's to the list.
	$self->install_modules( qw{
		SQL::Statement
		DBD::CSV
		DBD::Excel
	} ); # 3 (18)
	
	# Web Development

	# Catalyst::Runtime and prerequisites
	$self->install_modules( qw{
		Text::SimpleTable
		Class::C3::Adopt::NEXT
		MooseX::MethodAttributes::Inheritable
		HTTP::Request::AsCGI
		Tree::Simple
		String::RewritePrefix
		Tree::Simple::Visitor::FindByPath
		CGI::Simple::Cookie
		HTTP::Body
		MooseX::Emulate::Class::Accessor::Fast
		MooseX::Role::WithOverloading
		MooseX::Types::Common
		Catalyst::Runtime
	} ); # 13 (31)

	# Catalyst::Devel and prerequisites
	$self->install_modules( qw{
		MIME::Types
		Catalyst::Plugin::Static::Simple
		Devel::Caller
		MooseX::Params::Validate
		MooseX::SemiAffordanceAccessor
		File::ChangeNotify
		UNIVERSAL::isa
		UNIVERSAL::can
		Test::MockObject
		Catalyst::Action::RenderView
		Mouse
		Any::Moose
		Catalyst::Plugin::ConfigLoader
		Proc::Background
		Catalyst::Devel
	} ); # 15 (46)

	return 1;
}
	
sub install_satori_modules_4 {
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
		HTML::Tagset
	} ); # 10 (10)

	$self->install_modules( qw{
		Sub::Override
		HTML::TokeParser::Simple
		Tree::Simple::VisitorFactory
		Locale::Maketext::Lexicon
		Regexp::Assemble
		Log::Trace
		Test::Assertions
		Hash::Flatten
		Regexp::Copy
		HTML::Tiny
		Captcha::reCAPTCHA
		Bit::Vector
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
	} ); # 25 (35...)

	# Most of the rest of Web Development
	$self->install_modules( qw{
		Catalyst::Engine::Apache
		Catalyst::Log::Log4perl
		Catalyst::View::TT
		Catalyst::View::JSON
		Catalyst::Model::DBIC::Schema
		Catalyst::Plugin::Session
		Catalyst::Plugin::Authentication
		Catalyst::Plugin::StackTrace
		Catalyst::Plugin::FillInForm
		Catalyst::Plugin::I18N
		Catalyst::Plugin::Session::State::Cookie
		Catalyst::Plugin::Session::Store::File
		Catalyst::Plugin::Session::Store::Delegate
		Catalyst::Plugin::Session::Store::DBIC
		Catalyst::Plugin::Session::State::URI
		Catalyst::Plugin::Static::Simple
		Catalyst::Plugin::Authorization::Roles
	} ); # 17 (52)

	# Web Crawling and prereqs: LWP::Simple and everything 
	# in Bundle::LWP are already installed.
	# WWW::Mechanize is forced because the back test fails on the 
	# '404 check' test if the firewall is too severe.
	$self->install_module( name => 'HTTP::Server::Simple', );
	$self->install_module( name => 'WWW::Mechanize', force => 1, );
	$self->install_module( name => 'Test::WWW::Mechanize', force => 1, );

	# In Web Devel, but needed a prereq first.
	$self->install_module( name => 'Test::WWW::Mechanize::Catalyst', force => 1, );
	# 4 (56)
	
	$self->{force} = 0;

	# More of web development (C::P::A::ACL requires Test::WWW::Mech::Cat, and may need forced.)
	$self->install_modules( qw{
		Catalyst::Plugin::Authorization::ACL
		Catalyst::Controller::FormBuilder
		Catalyst::Component::InstancePerContext
		Catalyst::Authentication::Store::DBIx::Class
		FCGI::ProcManager
		CGI::FormBuilder::Source::Perl
		XML::RSS
		XML::Atom
		MIME::Types
	} ); # 9 (65)

	# E-mail Modules
	$self->install_modules( qw{
		Email::Valid
		Email::Sender
	} ); # 2 (67)

	# Localizing changes to environment for building purposes.
	{
		local $ENV{TZ} = 'PST8PDT';
		$self->install_module( name => 'Time::ParseDate' );
	} # 1 (68)
	
	# Last of Web Development
	# (HTML::FormFu requires the Email:: stuff.)
	$self->install_modules( qw{
		HTML::FormFu
		Catalyst::Controller::HTML::FormFu
	} ); # 2 (70)

	# Useful Command-line Tools prerequisites
	$self->install_modules( qw{
		File::Next
		MooseX::Object::Pluggable
		ExtUtils::Depends
		B::Utils
		Data::Dump::Streamer
		Devel::LexAlias
		Lexical::Persistence
		Test::Object
		WWW::Pastebin::PastebinCom::Create
		WWW::Pastebin::RafbNet::Create
		Win32::Clipboard
		Clipboard
		Mixin::Linewise
		App::Nopaste
		Module::Refresh
	} ); # 15 (85)

	# Useful Command-line Tools: Module::CoreList is 
	# already installed by Strawberry, and App::Ack 
	# is above.
	$self->install_modules( qw{
		Devel::REPL
	} ); # 1 (86)

	# Script Hackery prerequisites
	$self->install_modules( qw{
		File::ReadBackwards
		MLDBM
	} ); # 2 (88)

	# Script Hackery
	$self->install_modules( qw{
		Smart::Comments
		Term::ProgressBar::Simple
		IO::All
	} ); # 3 (91)

	# Socket6 would be nice to include, but it 
	# doesn't build due to referring to ws2_32.lib 
	# directly. A patch will be offered.
	
	# Asynchronous Programming and prerequisites
	$self->install_modules( qw{
		Win32::Console
		POE::Test::Loops
		POE
	} ); # 3 (94)

	# Final tasks
	$self->install_modules( qw{
		Task::Moose
		Task::Catalyst
		Task::Kensho
	} ); # 3 (97)
	
	return 1;
}
	
sub install_other_modules_1 {
	my $self = shift;

	# Graphical libraries (move to .par files)
	$self->install_modules( qw{
		Tk
		Prima
	} );
	$self->install_module(
		name  => 'Win32::GUI',
		force => 1,   # Fails a pod test.
	); # 3 (3)
	
	# Tkx needs Tcl, which needs a 'tclsh' binary.
	# Gtk2 requires binaries

	# CPAN helper.
	$self->install_modules( qw{
		CPANPLUS::Shell::Wx		
	} ); # 1 (4)

	# Pod Browser.
	$self->install_modules( qw{
		Tk::Pod		
	} ); # 1 (5)

	# Catalyst manual.
	$self->install_modules( qw{
		File::Monitor
		Catalyst::Manual		
	} ); # 2 (7)
	
	# BioPerl and as many of its optionals as possible.
	# GraphViz is a known problem - Beta 2?	
	$self->install_modules( qw{
		Data::Stag
		Ace
		Math::Random
		Math::Derivative
		SVG
		Graph
		SVG::Graph
		Parse::RecDescent
		Algorithm::MunkRes
		XML::Writer
		XML::DOM
		XML::XPathEngine
		XML::DOM::XPath
		XML::Simple
		XML::XPath
		HTML::TreeBuilder
		XML::Twig
		XML::Parser::PerlSAX
		PostScript::TextBlock
		Array::Compare
		Convert::Binary::C
		Set::Scalar
		Bio::Perl
	} ); # 23 (30)
	# This makes a circular dependency if I put it before Bio::Perl.
	$self->install_modules( qw{
		Bio::ASN1::EntrezGene
	} ); # 1 (31)

	# Padre Plugins.
	$self->install_modules( qw{
		Padre::Plugin::PerlTidy
		Padre::Plugin::PerlCritic
		Padre::Plugin::Catalyst
	} ); # 3 (34)

	# Perl::Shell and prereqs.
	$self->install_modules( qw{
		Test::Script
		Perl::Shell
	} ); # 2 (36)
	
	# The "pmtools".
	$self->install_modules( qw{
		Devel::Loaded
	} ); # 2 (36)

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

sub install_chocolate_extras {
	my $self = shift;

	my $sb_dist_dir = File::ShareDir::dist_dir('Perl-Dist-Strawberry');
	my $dist_dir = File::ShareDir::dist_dir('Perl-Dist-Chocolate');
	
	# Links to the Strawberry Perl website.
	# Don't include this for non-Strawberry sub-classes
	if ( ref($self) eq 'Perl::Dist::Chocolate' ) {
		# I'm not building this portable.
		$self->install_website(
			name       => 'Strawberry Perl Website',
			url        => $self->strawberry_url(),
			icon_file  => catfile($sb_dist_dir, 'strawberry.ico')
		);
		$self->install_website(
			name       => 'Strawberry Perl Professional Release Notes',
			url        => $self->chocolate_release_notes_url(),
			icon_file  => catfile($dist_dir, 'chocolate.ico')
		);
		# Link to IRC.
		$self->install_website(
			name       => 'Live Support',
			url        => 'http://widget.mibbit.com/?server=irc.perl.org&channel=%23win32',
			icon_file  => catfile($sb_dist_dir, 'onion.ico')
		);
		$self->patch_file( 'README.txt' => $self->image_dir(), { dist => $self } );
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
	  ->add_icon( catfile( $sb_dist_dir, 'padre.ico' ), 'padre.exe' );

	# Add the start menu icon.
	$self->get_fragment_object('StartMenuIcons')->add_shortcut(
		name => 'Padre',
		description =>
'Perl Application Development and Refactoring Environment - a Perl IDE',
		target      => "[D_$dir_id]padre.exe",
		id          => 'Padre',
		working_dir => $dir_id,
		icon_id     => $padre_icon_id,
	);

	$self->install_launcher(
		name => 'Graphical CPAN Client (TODO - needs work)',
		bin  => 'wxcpan',
	);

	$self->install_launcher(
		name => 'Graphical Documentation Browser',
		bin  => 'tkpod',
	);

	$self->install_launcher(
		name => 'Perl Shell (TODO - needs work)',
		bin  => 'perlthon',
	);

	my $chocolate_icon_id =
	  $self->_icons()
	  ->add_icon( catfile( $dist_dir, 'chocolate.ico' ), 'perl.exe' );

	$self->get_fragment_object('StartMenuIcons')->add_shortcut(
		name => 'Devel-REPL Shell (may need work)',
		description => 'Perl shell using Devel::REPL',
		target      => "[D_$dir_id]perl.exe",
		arguments   => '-S re.pl',
		id          => 'Devel_REPL',
		working_dir => $dir_id,
		icon_id     => $chocolate_icon_id,
	);

	
	$self->install_website(
		name       => 'Catalyst Web Framework',
		url        => 'http://www.catalystframework.org/',
		icon_file  => catfile($dist_dir, 'chocolate.ico')
	);
	
	$self->install_website(
		name       => 'Moose Web Framework',
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
		icon_file  => catfile($dist_dir, 'chocolate.ico')
	);

	$self->install_website(
		name       => 'Information about learning Perl',
		url        => 'http://learn.perl.org/',
		icon_file  => catfile($dist_dir, 'chocolate.ico')
	);

	$self->install_website(
		name       => 'Beginning Perl book',
		url        => 'http://learn.perl.org/books/beginning-perl/',
		icon_file  => catfile($dist_dir, 'chocolate.ico')
	);
	
	return 1;
}

	
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
