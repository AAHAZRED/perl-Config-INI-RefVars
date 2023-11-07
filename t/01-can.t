#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::AccVars;

ok(defined($Config::INI::AccVars::VERSION), '$VERSION is defined');

foreach my $meth (qw(new
            parse_ini)) {
  ok(Config::INI::AccVars->can($meth), "$meth() exists");
}

#==================================================================================================
done_testing();
