const { buildClientSchema, graphql } = require('graphql');
const fs = require('fs')

function runQuery(schemaContents, queryString) {
  let schema = buildClientSchema(schemaContents.data);

  // This can validate a query
  graphql(schema, queryString).then(function (result) {
    if(result['errors']) {
      console.log('ERROR', result);
      // Indicates error
      process.exit(1)
    } else {
      console.log('SUCCESS', result);
      // Indicates success
      process.exit(0)
    }
  });
}

// Fill this in with the schema string
let schemaString = process.env.SCHEMA_STRING;

// Make a GraphQL schema with no resolvers
let schemaContents = JSON.parse(schemaString);

// Fill this in with the query string
let queryString = process.env.QUERY_STRING;

if (typeof schemaContents.errors != 'undefined') {
  console.log('ERROR', 'Schema has errors in it');
  console.log(schemaContents.errors);
  // Indicates error
  process.exit(1)
} else if (typeof schemaContents.data != 'undefined') {
  runQuery(schemaContents, queryString)
} else {
  console.log('ERROR', 'Schema does not have errors or data');
  // Indicates error
  process.exit(1)
}
