# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use lib 't/lib';
use Helper;

subtest 'openapi object on the test itself' => sub {
  my $t = Test::Mojo->new($::app)
    ->with_roles('+OpenAPI::Modern')
    ->openapi($::openapi);

  $t->post_ok('/foo/hello')
    ->status_is(200)
    ->json_is('/status', 'ok')
    ->request_valid
    ->response_valid;
};

subtest 'openapi object is constructed using provided configs' => sub {
  my $schema = dclone($::schema);
  $schema->{info}{title} = 'Test API using overridden configs';

  my $t = Test::Mojo->new($::app, {
      openapi => {
        schema => $schema,
      }
    })
    ->with_roles('+OpenAPI::Modern');

  is($t->openapi->document_get('/info/title'), 'Test API using overridden configs',
    'test role constructs its own OpenAPI::Modern object');

  $t->post_ok('/foo/hello')
    ->status_is(200)
    ->json_is('/status', 'ok')
    ->request_valid
    ->response_valid;
};

done_testing;
