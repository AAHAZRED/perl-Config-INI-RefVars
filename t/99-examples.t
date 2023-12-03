use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

# use File::Spec::Functions qw(catdir catfile rel2abs splitpath);
use File::Spec::Functions;

sub test_data_file { catfile(qw(t 99_data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

subtest "SYNOPSIS" => sub {
  my $my_ini_file = test_data_file('dummy.ini');

  my $ini_reader = Config::INI::RefVars->new();
  $ini_reader->parse_ini(src => $my_ini_file);
  my $variables = $ini_reader->variables;
  while (my ($section, $section_vars) = each(%$variables)) {
    isa_ok($section_vars, 'HASH');
  }
};

#==================================================================================================
done_testing();
