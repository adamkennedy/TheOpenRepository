# Dear Distribution Packagers
#
# Hi there!
#
# Before we begin, I'm really really sorry for what you are about
# encounter a bit lower down in this file.
#
# Trust me, I didn't want to WRITE it just as much as you are probably
# not going to want to READ it and try to work out how the hell it
# applies to your Linux/etc distribution.
#
# So lets try to shortcut the whole confusion thing and save us both
# some time.
#
# Some distributions have this problem where the core Scalar::Util version
# in the Perl core gets built WITHOUT the compiler. When this happens,
# most of the functions in Scalar::Util that need the compiler are replaced
# with a Pure-Perl version that works almost identically...
#
# ...except for two relating to "weak references", which is a reference
# that is intentionally not counted for the purposes of garbage collection.
#
# It's used to implement certain specific data structures, like circular
# references and parent links in tree structures, in a way that can safely
# be garbage collected and won't leak.
#
# So what you really should check FIRST, is that the Perl build in your
# distribution has the Scalar::Util::weaken function defined.
#
# If not, then your Perl build is probably broken, and your solution
# ultimately needs to be applied to Perl itself. Then the whole problem
# goes away.
#
# If Scalar::Util::weaken is defined in your core Perl distribution, then
# none of the edge cases described below apply, and everything will be
# just rosy.
#
# Best Regards
#
# Adam K

use strict;
use inc::Module::Install;

name           'Task-Weaken';
all_from       'lib/Task/Weaken.pm';
build_requires 'Test::More'   => '0.42';
build_requires 'File::Spec'   => '0.80';

check_scalar_util();

WriteAll;

sub check_scalar_util {
	# Try to load Scalar::Util
	eval {
		require Scalar::Util;
	};
	if ( $@ ) {
		# Scalar::Util not installed (really old Perl?)
		requires 'Scalar::Util' => '1.14';
		return;
	}

	# Is installed
	my $module_version = $Scalar::Util::VERSION;
	my $module_weaken  = !! defined &Scalar::Util::weaken;
	if ( $module_weaken ) {
		# Already have weaken support.
		# Make sure it is a new enough version
		requires 'Scalar::Util' => '1.14';
		return;
	}

	# Does NOT have weaken, so either a very old
	# Scalar::Util, or a broken one.
	if ( $module_version <= 1.01 ) {
		# Very old Scalar::Util, upgrade it
		requires 'Scalar::Util' => '1.14';
		return;
	}

	# Broken Scalar::Util
	# That is, it does NOT contain the weaken function
	# which means it was built without a compiler.
	unless ( can_cc() ) {
		# The user does not have a compiler
		# There is currently no way to resolve
		# this situation, but we should probably
		# try to upgrade Scalar::Util anyway, just
		# in case the author is able to come up
		# with a solution at some point in the
		# future.
		message1();
		requires 'Scalar::Util' => '1.19';
		return;
	}

	# User should be capable of installing an
	# upgraded version.
	# Can we be certain they WILL do the upgrade?
	if ( $module_version < 1.19 ) {
		# We should be able to do a straight
		# forward upgrade of the module
		requires 'Scalar::Util' => '1.19';
		return;
	}

	# They ALREADY have the newest version... and it is broken.
	# Very little we can do in this case, other than issue a
	# message to the user, and then add a high dependency in the
	# vague hope it does something.
	message2();
	requires 'Scalar::Util' => '1.19';
	return;
}

sub message1 {
	print "\n\n\n";
	print "    ERROR:\n\n";
	print "    A CPAN module 
}
