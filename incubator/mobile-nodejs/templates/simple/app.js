const app = require('express')()
var passport = require('passport-mfp-token-validation').Passport;
var mfpStrategy = require('passport-mfp-token-validation').Strategy;

var MF_PROTOCOL = 'http';
var MF_HOST = ''; 
var MF_PORT = '80'; 

var authServerURL = MF_PROTOCOL + "://" + MF_HOST + ":" + MF_PORT + "/mfp/api" ; 
passport.use(new mfpStrategy({
  authServerUrl: authServerURL,
  confClientID: 'test',
  confClientPass: 'test',
  analytics: {
      onpremise: {
          url: 'http://localhost:9080/analytics-service/rest/v3',
          username: 'admin',
          password: 'admin'
      }
  }
}));
app.use(passport.initialize());


app.get('/', (req, res) => {
  res.send("Hello from Appsody!");
});


app.get('/service', passport.authenticate('mobilefirst-strategy', {
    session: false,
    scope: 'accessRestricted'
}),
function(req, res) {
    res.send(' If you are not authenticated, you will get a 401' );
});

 
module.exports.app = app;
