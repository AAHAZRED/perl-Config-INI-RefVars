use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::AccVars;

use File::Spec::Functions;


sub test_data_file { catfile(qw(t 02_data), $_[0]) }

subtest 'predefined sections' => sub {
  is(Config::INI::AccVars::COMMON_SECTION, "__COMMON__", "COMMON_SECTION default");
};

subtest 'before any parsing' => sub {
  my $obj = new_ok('Config::INI::AccVars');
  foreach my $meth (qw(sections
                       sections_h
                       variables
                       src_name
                       predef
                       common_section)) {
    is($obj->$meth, undef, "$meth(): undef");
  }
};


subtest 'empty input' => sub {
  subtest "string that only contains a line break" => sub {
    my $obj = new_ok('Config::INI::AccVars');
    is($obj->parse_ini(src => "\n"), $obj, "parse_ini() returns obj");
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj);
  };
  subtest "empty array" => sub {
    my $obj = new_ok('Config::INI::AccVars');
    $obj->parse_ini(src => []);
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj);
  };
  subtest "array containing an empty string" => sub {
    my $obj = new_ok('Config::INI::AccVars');
    $obj->parse_ini(src => [""]);
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj);
  };
  subtest "empty file" => sub {
    my $obj = new_ok('Config::INI::AccVars');
    my $empty_file = test_data_file("empty_file.ini");
    note("Input: $empty_file");
    $obj->parse_ini(src => $empty_file);
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj, $empty_file);
  };
  subtest "file containing only spaces" => sub {
    my $obj = new_ok('Config::INI::AccVars');
    my $spaces_file = test_data_file("only_spaces.ini");
    note("Input: $spaces_file");
    $obj->parse_ini(src => $spaces_file);
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj, $spaces_file);
  };
};


subtest 'only comments' => sub {
  subtest "string that only contains comments" => sub {
    my $obj = new_ok('Config::INI::AccVars');
    $obj->parse_ini(src => "; [a section]\n#foo=bar\n");
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj);
  };
  subtest "array containing only comments" => sub {
    my $obj = new_ok('Config::INI::AccVars');
    $obj->parse_ini(src => ["; [a section]",
                            ";foo=bar"]);
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj);
  };
  subtest "file containing only comments" => sub {
    my $obj = new_ok('Config::INI::AccVars');
    my $only_comments = test_data_file("only_comments.ini");
    note("Input: $only_comments");
    $obj->parse_ini(src => $only_comments);
    is_deeply($obj->sections,   [], 'sections(): empty array');
    is_deeply($obj->sections_h, {}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {}, 'variables(): empty hash');
    check_other($obj, $only_comments);
  };
};

subtest "simple content / reuse" => sub {
  my $obj = new_ok('Config::INI::AccVars');
  subtest "string input" => sub {
    $obj->parse_ini(src => "[a section]\nfoo=bar\n");
    is_deeply($obj->sections,   ['a section'],          'sections()');
    is_deeply($obj->sections_h, {'a section' => undef}, 'sections_h(): empty hash');
    is_deeply($obj->variables,  {'a section' => {foo => 'bar'}},
              'variables(): empty hash');
    check_other($obj);
  };
  subtest "file input" => sub {
    my $file = test_data_file('simple_content.ini');
    $obj->parse_ini(src => $file);
    is_deeply($obj->sections, ['first section',
                               'second section',
                               'empty section'],
              'sections()');
    is_deeply($obj->sections_h, { 'first section'  => undef,
                                  'second section' => undef,
                                  'empty section'  => undef,
                                },
              'sections_h()');
    is_deeply($obj->variables,  {'first section'  => {var_1 => 'val_1',
                                                      var_2 => 'val_2'},
                                 'second section' => {this => 'that'},
                                },
              'variables()');
    check_other($obj, $file);
  };
  subtest "file input (with and without newlines)" => sub {
    $obj->parse_ini(src => ["[sec-1]",
                            "a = a_val\n",
                            "b=#;;#",
                            "",
                            "  [  sec-2   ]\n",
                            "  var   =   val"
                           ]);
    is_deeply($obj->sections, [qw(sec-1 sec-2)], 'sections()');
    is_deeply($obj->sections_h, { 'sec-1' => undef,
                                  'sec-2' => undef
                                },
              'sections_h()');
    is_deeply($obj->variables,  { 'sec-1' => {a => 'a_val', b => '#;;#' },
                                  'sec-2' => {var => 'val'}
                                  },
              'variables()');
    check_other($obj);
  };
};


subtest "common section" => sub {
  my $obj = new_ok('Config::INI::AccVars');
  my $input = ["a=b",
               "[blah]",
               "A=B"];
  is($obj->parse_ini(src => $input), $obj, "parse_ini() returns obj");
  is_deeply($obj->sections, [Config::INI::AccVars::COMMON_SECTION, "blah"],
            "sections(): default and empty section");
  is_deeply($obj->sections_h, { Config::INI::AccVars::COMMON_SECTION => undef,
                                'blah'                               => undef},
            'sections_h()');
  is_deeply($obj->variables,  { Config::INI::AccVars::COMMON_SECTION => {a => 'b'},
                                'blah'                               => {A => 'B'},
                              },
               'variables()');
  check_other($obj);
};


subtest "arguments" => sub {
  my $obj = new_ok('Config::INI::AccVars');
  my $input = ["a=b",
               "[]",
               "A=B"];
  subtest "clone + predef (empty)" => sub {
    my $predef = {};
    $obj->parse_ini(src => $input, predef => $predef);
    is_deeply($obj->predef, {}, "predef() is {}");
    is($obj->predef, $predef, "predef is not cloned");

    $obj->parse_ini(src => $input, predef => $predef, clone => 1);
    is_deeply($obj->predef, {}, "predef() is {}");
    isnt($obj->predef, $predef, "predef is not cloned");
  };
};

#==================================================================================================
done_testing();


###################################################################################################

sub check_other {
  my $obj = shift;
  my $src_name = shift // "INI data";
  is_deeply($obj->predef, {}, 'predef()');
  is($obj->common_section,  Config::INI::AccVars::COMMON_SECTION, 'common_section()');
}
