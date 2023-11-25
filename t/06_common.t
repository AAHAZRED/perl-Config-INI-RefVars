use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

#use File::Spec::Functions;
#
#sub test_data_file { catfile(qw(t 05_data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#


my $obj = Config::INI::RefVars->new;

subtest "basic" => sub {
  ok 1;
};


#==================================================================================================
done_testing();

