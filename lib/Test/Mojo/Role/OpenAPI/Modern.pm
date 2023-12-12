use strict;
use warnings;
package Test::Mojo::Role::OpenAPI::Modern;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Test::Mojo role providing access to an OpenAPI document and parser
# KEYWORDS: validation evaluation JSON Schema OpenAPI Swagger HTTP request response

our $VERSION = '0.003';

use 5.020;  # for fc, unicode_strings features
use strictures 2;
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use namespace::clean;

use Mojo::Base -role, -signatures;

has 'openapi' => sub ($self) {
  # use the plugin's object, if the plugin is being used
  # FIXME: we should be calling $self->app->$_call_if_can, but can() isn't behaving
  my $openapi = eval { $self->app->openapi };
  return $openapi if $openapi;

  # otherwise try to construct our own using provided configs
  if (my $config = $self->app->config->{openapi}) {
    return $config->{openapi_obj} if $config->{openapi_obj};

    if (my $args = eval {
        +require Mojolicious::Plugin::OpenAPI::Modern;
        Mojolicious::Plugin::OpenAPI::Modern->VERSION('0.007');
        Mojolicious::Plugin::OpenAPI::Modern::_process_configs($config);
      }) {
      return OpenAPI::Modern->new($args);
    }
  }

  die 'openapi object or configs required';
};

sub request_valid ($self, $desc = 'request is valid') {
  my $result = $self->openapi->validate_request($self->tx->req);
  return $self->test('ok', $result, $desc);
}

sub response_valid ($self, $desc = 'response is valid') {
  my $options = { request => $self->tx->req };
  my $result = $self->openapi->validate_response($self->tx->res, $options);
  return $self->test('ok', $result, $desc);
}

1;
__END__

=pod

=for stopwords OpenAPI openapi

=head1 SYNOPSIS

  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => YAML::PP->new(boolean => 'JSON::PP')->load_string(<<'YAML'));
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

  my $t = Test::Mojo
    ->with_roles('+OpenAPI::Modern')
    ->new('MyApp', { ... })
    ->openapi($openapi);

  $t->post_ok('/foo/hello')
    ->status_is(200)
    ->json_is('/status', 'ok')
    ->request_valid
    ->response_valid;

=head1 DESCRIPTION

Provides methods on a L<Test::Mojo> object suitable for using L<OpenAPI::Modern> to validate the
request and response.

=head1 ACCESSORS/METHODS

=head2 openapi

The L<OpenAPI::Modern> object to use for validation. This object stores the OpenAPI schema used to
describe requests and responses in your application, as well as the underlying
L<JSON::Schema::Modern> object used for the validation itself. See that documentation for
information on how to customize your validation and provide the specification document.

If not provided, the object is constructed using configuration values passed to the application
under the C<openapi> key (see L<Test::Mojo/new>), as for L<Mojolicious::Plugin::OpenAPI::Modern>,
or re-uses the object from the application itself if that plugin is applied.

=head2 request_valid

Passes C<< $t->tx->req >> to L<OpenAPI::Modern/validate_request>, as in
L<Mojolicious::Plugin::OpenAPI::Modern/validate_request>, producing a boolean test result.

=head2 response_valid

Passes C<< $t->tx->res >> to L<OpenAPI::Modern/validate_response> as in
L<Mojolicious::Plugin::OpenAPI::Modern/validate_response>, producing a boolean test result.

=head1 FUTURE FEATURES

Lots of features are still to come, including:

=for :list
* C<request_invalid>, C<response_invalid> test methods, including a mechanism for providing the
  expected validation error(s)
* stashing the validation results on the test object for reuse or diagnostic printing
* integration with L<Mojolicious::Plugin::OpenAPI::Modern>, including sharing the openapi object and
  customization options that are set in the application

=head1 SEE ALSO

=for :list
* L<Mojolicious::Plugin::OpenAPI::Modern>
* L<Test::Mojo>
* L<Test::Mojo::WithRoles>
* L<OpenAPI::Modern>
* L<JSON::Schema::Modern::Document::OpenAPI>
* L<JSON::Schema::Modern>
* L<https://json-schema.org>
* L<https://www.openapis.org/>
* L<https://learn.openapis.org/>
* L<https://spec.openapis.org/oas/v3.1.0>

=cut
