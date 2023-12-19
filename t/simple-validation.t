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
use Test::Needs;
use Scalar::Util 'refaddr';

subtest 'openapi object on the test itself' => sub {
  my $t = Test::Mojo
    ->with_roles('+OpenAPI::Modern')
    ->new($::app)
    ->openapi($::openapi);

  $t->post_ok('/foo/123', json => {})
    ->status_is(200)
    ->json_is('/status', 'ok')
    ->request_valid
    ->response_valid;

  my $request_result = $t->request_validation_result;
  $t->request_valid;
  is(refaddr($request_result), refaddr($t->request_validation_result),
    'same result object is returned the second time');

  $t->post_ok('/foo/123', json => {});
  isnt(refaddr($request_result), refaddr(my $new_request_result = $t->request_validation_result),
    'different result object is returned for a different request');
  is(refaddr($new_request_result), refaddr($t->request_validation_result),
    'same result object is returned for the second request again');

  $t->post_ok('/foo/123', form => { salutation => 'hi' })
    ->status_is(400)
    ->content_is('kaboom')
    ->request_not_valid
    ->response_not_valid;

  is(
    Mojo::JSON::Pointer->new($t->request_validation_result->TO_JSON)->get('/errors/0/error'),
    'incorrect Content-Type "application/x-www-form-urlencoded"',
    'request validation error',
  );

  is(
    Mojo::JSON::Pointer->new($t->response_validation_result->TO_JSON)->get('/errors/0/error'),
    'no response object found for code 400',
    'response validation error',
  );
};

subtest 'openapi object is constructed using provided configs' => sub {
  test_needs 'Mojolicious::Plugin::OpenAPI::Modern';

  my $schema = dclone($::schema);
  $schema->{info}{title} = 'Test API using overridden configs';

  my $t = Test::Mojo
    ->with_roles('+OpenAPI::Modern')
    ->new($::app, {
      openapi => {
        schema => $schema,
      }
    });

  is($t->openapi->document_get('/info/title'), 'Test API using overridden configs',
    'test role constructs its own OpenAPI::Modern object');

  $t->post_ok('/foo/123', json => {})
    ->status_is(200)
    ->json_is('/status', 'ok')
    ->request_valid
    ->response_valid;
};

done_testing;
