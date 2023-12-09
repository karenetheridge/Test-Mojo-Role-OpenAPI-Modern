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

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Mojolicious;
use Mojo::URL;
use YAML::PP 0.005;
use OpenAPI::Modern;
use Test::Mojo;

my $openapi_preamble = <<'YAML';
---
openapi: 3.1.0
info:
  title: Test API
  version: 1.2.3
YAML

my $doc_uri = Mojo::URL->new('https://example.com/api');
my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

my $app = Mojolicious->new;
$app->routes->post('/foo/:foo_id' => sub ($c) { $c->render(json => { status => 'ok' }) });


subtest 'openapi object on the test itself' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<'YAML'));
---
openapi: 3.1.0
info:
  title: Test API
  version: 1.2.3
paths:
  /foo/{foo_id}:
    parameters:
    - name: foo_id
      in: path
      required: true
      schema:
        pattern: ^[a-z]+$
    post:
      operationId: my_foo_request
      requestBody:
        required: true
        content:
          application/json:
            schema: {}
      responses:
        200:
          description: success
          content:
            application/json:
              schema:
                type: object
                required: [ status ]
                properties:
                  status:
                    const: ok
YAML


  my $t = Test::Mojo->new($app)
    ->with_roles('+OpenAPI::Modern')
    ->openapi($openapi);

  $t->post_ok('/foo/hello')
    ->status_is(200)
    ->json_is('/status', 'ok')
    ->request_valid
    ->response_valid;
};

done_testing;
