#
#===============================================================================
#
#         FILE:  Deep-Encode-01.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Grishaev Anatoliy (ga), zua.zuz@toh.ru
#      COMPANY:  Adeptus, Russia
#      VERSION:  1.0
#      CREATED:  09/20/10 13:56:34
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Test::More 'no_plan';                      # last test to print
#use ExtUtils::testlib;
use Deep::Encode qw(deep_utf8_off);

my $s1 = chr(1);
my $x;
for my $t ( 
	'deep_utf8_off( $x = chr(1) ) == 0',
	'deep_utf8_off( $x = chr(256) ) == 1',
	'deep_utf8_off( $x = [ chr(1), chr(256), chr(257)] ) == 2',
	){
    ok( scalar eval $t, $t);
}



