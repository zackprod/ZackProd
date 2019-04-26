var express = require('express');
var bodyParser = require('body-parser');
var cors = require('cors');

var app = express();
var http=require('http');
const dgram = require('dgram');
const server = dgram.createSocket('udp4');
var io = require('socket.io')(http);


var { pg, Client } = require("pg");

const connectionString = "postgres://postgres:ucf@localhost:5432/Projet";

const client = new Client({
    connectionString: connectionString
});













/**************** Socket  *************/
io.set("origins","*:*");

io.on('connection',function(){

console.log("react Js connecter")

});






server.on('error', (err) => {
  console.log(`server error:\n${err.stack}`);
  server.close();
});

server.on('message', (msg, rinfo) => {
  console.log(`server got: ${msg} from ${rinfo.address}:${rinfo.port}`);
io.emit("SetData","Salam");


});

server.on('listening', () => {
  const address = server.address();
  console.log(`server listening ${address.address}:${address.port}`);
});

server.bind(7770);

io.listen(7771);

/********************************************************************************/








client.connect();
app.use(cors());

app.use(bodyParser.json());

app.use(bodyParser.urlencoded({
    extended: false
}));

app.use(express.static(__dirname + '/build'))



app.get('/', function(req, res){

    // save html files in the `views` folder...
    res.sendfile(__dirname + "/build/index.html");
});




app.get('/connexionoperateur', async function (req, response) {


    if (req.query.id != 0) {
        var quer = "select ConnextionOperateur('" + req.query.id + "') as a;"
         console.log(quer);
        await client.query(quer, (err, res) => {
            if (err) {
                console.log("erreur")
                response.end();

            } else {
                response.json(res.rows[0].a);

            }

        });

    }

});









app.get('/SaveProduit', async function (req, response) {
  response.writeHead(200, {
      'Content-Type': 'application/json',
      'Trailer': 'Content-MD5'
  });

    if (req.query.id != 0) {
        var quer = "insert into Pieces(idop,cat,shiftp,timing,status)  values('"+req.query.idop+"','"+req.query.cat+"','"+req.query.shift+"',current_timestamp,'"+req.query.status+"');";
        console.log(quer);
        await client.query(quer, (err) => {
            if (err) {
              console.log("erreur");

              response.end();
            } else {
                console.log('Done');
                response.write("1");
                response.end();
            }

        });

    }

});




app.get('/tictimereeltime', async function (req, response) {
    response.writeHead(200, {
        'Content-Type': 'application/json',
        'Trailer': 'Content-MD5'
    });
        var quer = "select array_to_json(array_agg(row_to_json(t))) as a from (select  id,idop,cat,shiftp,timing,status,get_tic_time(id,idop,shiftp) as tictime from pieces where shiftp='"+req.query.shift+"'AND idop='"+req.query.idop+"' AND DATE(timing) = current_date limit 25)t;";
console.log(quer);
        await client.query(quer, (err, res) => {
            if (err) {
                console.log("erreur")
                response.end();

            } else {
                response.write(JSON.stringify(res.rows[0].a));
                response.end();

            }

        });



});




app.get('/DataShiftReeltime', async function (req, response) {
    response.writeHead(200, {
        'Content-Type': 'application/json',
        'Trailer': 'Content-MD5'
    });

    if (req.query.id != 0) {
        var quer = "select getreeltime('"+ req.query.id +"') as A;"
        console.log(quer);
        await client.query(quer, (err, res) => {
            if (err) {
                console.log("erreur")
                response.end();

            } else {

                response.write(JSON.stringify(res.rows[0].a));
                response.end();

            }


        });





    }

});



app.get('/operateurreeltime',  function (req, response) {
    response.writeHead(200, {
        'Content-Type': 'application/json',
        'Trailer': 'Content-MD5'
    });
      //  var quer = "select array_to_json(array_agg(row_to_json(t))) as a from (select operateur.idoperateur,operateur.username,operateur.email,operateur.shift  from operateur,shift where operateur.shift=shift.id AND current_time between shift.begintime and shift.endtime)t;";
        var quer = "select get_operateur_reeltime() as a";

         client.query(quer, (err, res) => {
            if (err) {
                console.log("erreur")
                response.end();

            } else {
                response.write(JSON.stringify(res.rows[0].a));
                response.end();

            }

        });

});


app.get('/operateur',  function (req, response) {
    response.writeHead(200, {
        'Content-Type': 'application/json',
        'Trailer': 'Content-MD5'
    });
      //  var quer = "select array_to_json(array_agg(row_to_json(t))) as a from (select operateur.idoperateur,operateur.username,operateur.email,operateur.shift  from operateur,shift where operateur.shift=shift.id AND current_time between shift.begintime and shift.endtime)t;";
        var quer = "select array_to_json(array_agg(row_to_json(t)))from (select * from operateur)t";

         client.query(quer, (err, res) => {
            if (err) {
                console.log("erreur")
                response.end();

            } else {
                response.write(JSON.stringify(res.rows[0].array_to_json));
                response.end();

            }

        });

});






app.listen(8765);
