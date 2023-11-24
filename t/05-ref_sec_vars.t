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


subtest "basic sec refs" => sub {
  subtest "very simpls, usinf = and ==" => sub {
    my $src = <<'EOT';
[sec A]
X = Reference from other section: $([sec B]str)
Y = From variable $(==) in section $(=)

[sec B]
X = Reference: $([sec A]Y)
str = huhu --->$(=)
EOT
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'sec A' => {
                           # Note the value of Y: "... ---> sec B"!
                           'X' => 'Reference from other section: huhu --->sec B',
                           'Y' => 'From variable Y in section sec A'
                          },
               'sec B' => {
                           'str' => 'huhu --->sec B',
                           'X' => 'Reference: From variable Y in section sec A'
                          }
              },
              'variables()');
  };
#  subtest "sec name in variable"
};

subtest "chains" => sub {
  subtest "[section 1] ... [section 7]" => sub {
    my $src = [
               '[section 1]',
               'a= Variable $(==) in sectiom $(=)',
               'b=$([section 1]a)',
               # ---
               '[section 2]',
               'a=$([section 1]a)',
               'b=$([section 1]a)',
               # ---
               '[section 3]',
               'a=$([section 1]a)',
               'b=$([section 2]a)',
               # ---
               '[section 4]',
               'a=$([section 1]a)',
               'b=$([section 3]a)',
               # ---
               '[section 5]',
               'a=$([section 1]a)',
               'b=$([section 4]a)',
               # ---
               '[section 6]',
               'a=$([section 1]a)',
               'b=$([section 5]a)',
               # ---
               '[section 7]',
               'a=$([section 1]a)',
               'b=$([section 6]a)',
              ];
    $obj->parse_ini(src => $src);
    while (my ($sec, $val) = each(%{$obj->variables})) {
      is_deeply($val, {
                       'a' => 'Variable a in sectiom section 1',
                       'b' => 'Variable a in sectiom section 1'
                      },
                "section '$sec'");
    }
    is_deeply($obj->sections_h, {
                                 'section 1' => 0,
                                 'section 2' => 1,
                                 'section 3' => 2,
                                 'section 4' => 3,
                                 'section 5' => 4,
                                 'section 6' => 5,
                                 'section 7' => 6,
                                },
              "sections_h"
              );
  };
};

#==================================================================================================
done_testing();

