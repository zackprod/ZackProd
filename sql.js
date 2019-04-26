var { pg, Client } = require("pg");

const connectionString = "postgres://postgres:ucf@localhost:5432/postgres";

const client = new Client({
    connectionString: connectionString
});
client.connect();

var fs = require('fs');
 
var contents = fs.readFileSync('database.sql', 'utf8');



client.query("CREATE DATABASE Projet ", (err, res) => {
   if (err) {
       console.log(err);

   } else {
        console.log("done");
   }

});

client.query(contents, (err, res) => {
    if (err) {
        console.log(err);
 
    } else {
         console.log("done");
    }
 
 });