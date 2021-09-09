# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v0.6.4 (2021-03-10)
- [PR 24](https://github.com/annkissam/common_graphql_client/pull/24)
Add Tesla caller `CommonGraphQLClient.Caller.HttpTesla`

## v0.6.3 (2020-12-01)
- [PR 19](https://github.com/annkissam/common_graphql_client/pull/19)
Update `StaticValidator.NpmGraphql` to accept `schema_path` or `schema_string`

## v0.6.2 (2020-11-30)
Bump `graphql` (^15.4.0) & `graphql-tools` (^7.0.2) devDependencies

## v0.6.0 (2020-05-05)
- [PR 17](https://github.com/annkissam/common_graphql_client/pull/17)
Dynamic http api token and url support (Breaking change)

## v0.5.0 (2020-05-04)
- [PR 15](https://github.com/annkissam/common_graphql_client/pull/15) Static Validation for query
on the client side using npm_graphql

## v0.3.3 (2019-09-17)
- [PR 13](`CommonGraphQLClient.Caller.Http.post\4`) Better HTTPoison error handling in `CommonGraphQLClient.Caller.Http.post\4`
- Allow http_opts to be sent to `CommonGraphQLClient.Caller.Http.post\4`

## v0.3.3 (2019-09-17)
- Fix UndefinedFunctionError error on Caller.Http.post & Caller.Nil.post

## v0.3.1 (2019-02-08)
- Add configurable timeout and error logging (https://github.com/annkissam/common_graphql_client/pull/9)

## v0.3.0 (2018-07-11)

- Initial Public Release
