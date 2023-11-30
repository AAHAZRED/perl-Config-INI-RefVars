use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Config::INI::RefVars;

# use File::Spec::Functions qw(catdir catfile rel2abs splitpath);
#
#sub test_data_file { catfile(qw(t 08_data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

my $Dummy_Src = [
                 '[The Section]',
                 'The Variable=007'
                ];

subtest "common_vars" => sub {
  subtest 'new()' => sub {
    like(exception { Config::INI::RefVars->new(common_vars => 72) },
         qr/'common_vars': expected HASH ref/,
         "common_vars: the code died as expected");

    like(exception { Config::INI::RefVars->new(common_vars => []) },
         qr/'common_vars': expected HASH ref/,
         "common_vars: the code died as expected");

    like(exception { Config::INI::RefVars->new(common_vars => {
                                                               x => 'huhu',
                                                               y => {},
                                                               z => 23
                                                              }) },
         qr/'common_vars': value of 'y' is a ref, expected scalar/,
         "common_vars: the code died as expected");

    like(exception { Config::INI::RefVars->new(common_vars => {
                                                               x      => 'huhu',
                                                               '=foo' => '',
                                                               z      => 23
                                                              }) },
         qr/'common_vars': variable '=foo': name is not permitted/,
         "common_vars: the code died as expected");

    like(exception { Config::INI::RefVars->new(common_vars => {
                                                               x      => 'huhu',
                                                               ';foo' => '',
                                                               z      => 23
                                                              }) },
         qr/'common_vars': variable ';foo': name is not permitted/,
         "common_vars: the code died as expected");
  };

  subtest 'parse_ini()' => sub {
    my $obj = Config::INI::RefVars->new();

    like(exception { $obj->parse_ini(src => $Dummy_Src, common_vars => 72) },
         qr/'common_vars': expected HASH ref/,
         "common_vars: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, common_vars => []) },
         qr/'common_vars': expected HASH ref/,
         "common_vars: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, common_vars => {
                                                                        x => 'huhu',
                                                                        y => {},
                                                                        z => 23
                                                                       }) },
         qr/'common_vars': value of 'y' is a ref, expected scalar/,
         "common_vars: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, common_vars => {
                                                                        x      => 'huhu',
                                                                        '=foo' => '',
                                                                        z      => 23
                                                              }) },
         qr/'common_vars': variable '=foo': name is not permitted/,
         "common_vars: the code died as expected");

    like(exception { $obj->parse_ini(src => $Dummy_Src, common_vars => {
                                                                        x      => 'huhu',
                                                                        ';foo' => '',
                                                                        z      => 23
                                                                       }) },
         qr/'common_vars': variable ';foo': name is not permitted/,
         "common_vars: the code died as expected");
  };
};

#==================================================================================================
done_testing();
