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

subtest 'request or response not valid' => sub {
  my $t = Test::Mojo
    ->with_roles('+OpenAPI::Modern')
    ->new($::app)
    ->openapi($::openapi);

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

done_testing;
