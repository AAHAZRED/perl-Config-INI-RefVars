use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::AccVars;

use File::Spec::Functions;


sub test_data_file { catfile(qw(t 03_data), $_[0]) }

subtest "basic assignments" => sub {
  my $obj = Config::INI::AccVars->new;
  foreach my $file (test_data_file('basic.ini'), test_data_file('basic_spaces.ini')) {
    subtest $file => sub {
      $obj->parse_ini(src => $file);
      is_deeply($obj->sections, [Config::INI::AccVars::DFLT_COMMON_SECTION, "this section"],
                "sections()");
      is_deeply($obj->sections_h, { Config::INI::AccVars::DFLT_COMMON_SECTION => undef,
                                    "this section"                            => undef },
                "sections_h()");
      is_deeply($obj->variables, { Config::INI::AccVars::DFLT_COMMON_SECTION => {foo => 'foo_val'},
                                   "this section" => {str => "hello world"}
                                 },
                "variables()");
    };
  }
};

#==================================================================================================
done_testing();

