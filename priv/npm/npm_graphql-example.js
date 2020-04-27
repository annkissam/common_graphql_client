var _graphqlTools = require("graphql-tools");

var _graphql = require("graphql");

var schemaString = "\ntype Author {\n    firstName: String\n    lastName: String\n  }\n  type Query {\n    author(id: Int!): Author\n  }\n"; // Make a GraphQL schema with no resolvers

var schema = (0, _graphqlTools.makeExecutableSchema)({
  typeDefs: schemaString
});

(0, _graphqlTools.addMocksToSchema)({
  schema: schema
});

var query = "\n  { __typename }\n";

(0, _graphql.graphql)(schema, query).then(function (result) {
  if(result['errors']) {
    console.log('ERROR', result);
    process.exit(1)
  } else {
    console.log('SUCCESS', result);
    process.exit(0)
  }
});
