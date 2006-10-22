use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'File::Remove',
    VERSION_FROM      => 'lib/File/Remove.pm', # finds $VERSION
    PREREQ_PM         => {
        'File::Spec' => 0.84,
	'File::Path' => 0,
	'File::Glob' => 0,
	# Win32::FileOp requires Win32::API
	# Win32::API is not working at time of writing.
	#($^O eq 'MSWin32' or $^O eq 'cygwin')
	#	? ('Win32::FileOp' => 0)
	#	: (),
	($^O eq 'darwin')
		? ('Mac::Glue' => 0)
		: (),
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/Remove.pm', # retrieve abstract from module
       AUTHOR         => 'Richard Soderberg <rs@localdomain>') : ()),
);
