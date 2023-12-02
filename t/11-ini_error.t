use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Warn;


use Config::INI::RefVars;

# use File::Spec::Functions qw(catdir catfile rel2abs splitpath);
#
#sub test_data_file { catfile(qw(t 08_data), $_[0]) }

#8

# For heredocs containing INI data always use the single quote variant!
#

subtest "section header" => sub {
  my $obj = Config::INI::RefVars->new();

  like(exception { $obj->parse_ini(src_name => "my INI",
                                   src      => [
                                                '[sec1]',
                                                'a=b',
                                                '[sec2'
                                               ]) },
       qr/'my INI': invalid section header at line 3 /,
       "section header: the code died as expected");

  like(exception { $obj->parse_ini(src_name => "my INI",
                                   src      => [
                                                '[sec1 ; ]  ; comment',
                                                '[sec2 # ] # comment',
                                                '',
                                                '[sec3 ; ] ; ] comment'
                                               ]) },
       qr/'my INI': invalid section header at line 4 /,
       "section header: the code died as expected");

  like(exception { $obj->parse_ini(src_name => "my INI",
                                   src      => [
                                                '[sec1 ; ]  ; comment',
                                                '[sec2 # ] # comment',
                                                '',
                                                '[sec1 ; ] ; comment'
                                               ]) },
       qr/'my INI': 'sec1 ;': duplicate header at line 4 /,
       "section header: the code died as expected");

  like(exception { $obj->parse_ini(src_name => "my INI",
                                   src      => [
                                                'a=b',
                                                '[__COMMON__]',
                                               ]) },
       qr/'my INI': common section '__COMMON__' must be first section at line 2 /,
       "section header: the code died as expected");

  like(exception { $obj->parse_ini(src_name => "my INI",
                                   src      => [
                                                'a=b',
                                                '[__COMMON__]',
                                               ]) },
       qr/'my INI': common section '__COMMON__' must be first section at line 2 /,
       "section header: the code died as expected");

  like(exception { $obj->parse_ini(src_name => "my INI",
                                   src      => [
                                                '[sec]',
                                                'a=b',
                                                '[__COMMON__]',
                                               ]) },
       qr/'my INI': common section '__COMMON__' must be first section at line 3 /,
       "section header: the code died as expected");
};


#==================================================================================================
done_testing();

