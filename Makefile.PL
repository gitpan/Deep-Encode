use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
unless( $] >= 5.008000 ){
	print STDERR "perl 5.8.0 required. would not build\n";	
	exit 0;
}
WriteMakefile(
    NAME              => 'Deep::Encode',
    VERSION_FROM      => 'lib/Deep/Encode.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Deep/Encode.pm', # retrieve abstract from module
       AUTHOR         => 'A. G. Grishaev <grian@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
