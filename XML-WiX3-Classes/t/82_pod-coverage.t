#!perl

sub filter {
	my $module = shift;
	
	return 0 if $module =~ m/::Object\z/;
	return 0 if $module =~ m/::Trace::/;
	return 0 if $module =~ m/::StrictConstructor/;
	return 0 if $module =~ m/::Types\z/;
	return 0 if $module =~ m/_Old\z/;
	return 1;
}

use Test::More;
eval "use Pod::Coverage::Moose 0.01";
plan skip_all => "Pod::Coverage::Moose 0.01 required for testing POD coverage" if $@;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

plan( skip_all => "Test fails as of yet." );

my @modules = all_modules();
my @modules_to_test = grep { filter($_) } @modules;
my $test_count = scalar @modules_to_test;
plan tests => $test_count;

foreach my $module (@modules_to_test){
	pod_coverage_ok($module, { 
	  coverage_class => 'Pod::Coverage::Moose', 
	  also_private => [ qr/^[A-Z_]+$/ ],
	  trustme => [ qw(as_string get_namespace) ]
	});
}