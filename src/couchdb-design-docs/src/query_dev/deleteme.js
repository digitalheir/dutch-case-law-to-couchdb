var v =require('./views')
var natural = require('./natural')
var tokenizer = new natural.WordPunctTokenizer();
var str = tokenizer.tokenize("Hallo, ik ben een test! :p 33-1:ECLI:30.");
console.log(str);

