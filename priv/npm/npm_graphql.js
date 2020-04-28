var _graphqlTools = require("graphql-tools");

var _graphql = require("graphql");

// Fill this in with the schema string
var schemaString = process.env.SCHEMA_STRING; // Make a GraphQL schema with no resolvers

var schema = (0, _graphqlTools.makeExecutableSchema)({
  typeDefs: schemaString
});

// Add mocks, modifies schema in place
(0, _graphqlTools.addMocksToSchema)({
  schema: schema
});

// Fill this in with the query_string string
var query = process.env.QUERY_STRING;

(0, _graphql.graphql)(schema, query).then(function (result) {
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
