#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Config::INI::AccVars' ) || print "Bail out!\n";
}

diag( "Testing Config::INI::AccVars $Config::INI::AccVars::VERSION, Perl $], $^X" );
