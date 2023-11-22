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

subtest "basic" => sub {
  my $obj = Config::INI::RefVars->new;
  my $src = <<'EOT';
[sec A]
X = Reference from other section: $([sec B]str)
Y = From variable $(==) in section $(=)

[sec B]
X = Reference: $([sec A]Y)
str = huhu
EOT
  $obj->parse_ini(src => $src);
  is_deeply($obj->variables,
            {
             'sec A' => {
                         'X' => 'Reference from other section: huhu',
                         'Y' => 'From variable Y in section sec A'
                        },
             'sec B' => {
                         'str' => 'huhu',
                         'X' => 'Reference: From variable Y in section sec A'
                        }
            },
            'variables()');
};

#==================================================================================================
done_testing();

