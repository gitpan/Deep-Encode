#===============================================================================
#
#         FILE:  Deep-Encode-05.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  01/27/2011 01:50:25 PM
#     REVISION:  ---
#===============================================================================


use strict;
use warnings;
no warnings 'uninitialized';
use Test::More qw(no_plan);
use ExtUtils::testlib;
use Deep::Encode qw(deep_str_clone);
use Scalar::Util qw(refaddr);



my $wide=chr(128);
is( $_, deep_str_clone( $_ ), "scalar clone '$_'" ) for 1, undef, 0, "", "abc", chr(128), chr(20000);

is_deeply( deep_str_clone( $_ ), $_ , "deep clone" ) for { a=> 1}, [ a=>1,2, chr(128)], { a=>{b=>1}, c=>[d=>2,3]};


my $s = [ 0, undef, "abc", chr(128 ), [$wide]];
my $m = deep_str_clone( $s );

ok( a_equal( \$s->[0], \$m->[0]), "s[0]");
ok( a_equal( \$s->[1], \$m->[1]), "s[1]");
ok( a_equal( \$s->[2], \$m->[2]), "s[2]");

ok( !a_equal( \$s->[3], \$m->[3]), "s[3]");
ok( !a_equal( \$s->[4], \$m->[4]), "s[4]");


$s = [ 0, 1, 10 ];
$m = deep_str_clone( $s );
ok( a_equal( $s, $m ), "[0,1,10]");
$s =  [ 0, $wide, 10 ];
$m = deep_str_clone( $s );
ok( !a_equal( $s, $m ), "[0,W,10]");

$s =  [ $wide, 1, 10 ];
$m = deep_str_clone( $s );
ok( !a_equal( $s, $m ), "[w,1,10]");

$s =  [ 0, 1, $wide ];
$m = deep_str_clone( $s );
ok( !a_equal( $s, $m ), "[0,1,w]");



$s = {a=>0, b=>1, c=>10};
$m = deep_str_clone( $s );
ok( a_equal( $s, $m ), "H[0,1,10]");

$s = {a=>$wide, b=>1, c=>10};
$m = deep_str_clone( $s );
ok( !a_equal( $s, $m ), "H[w,1,10]");

$s = {a=>0, b=>$wide, c=>10};
$m = deep_str_clone( $s );
ok( !a_equal( $s, $m ), "H[0,W,10]");

$s = {a=>0, b=>1, c=>$wide};
$m = deep_str_clone( $s );
ok( !a_equal( $s, $m ), "H[0,1,w]");

sub a_equal{
	refaddr( $_[0] ) == refaddr( $_[1] );
}

