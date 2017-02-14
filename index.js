// NOTE: This code is based on the following Github Pull Request comment
// https://github.com/nodejs/node/issues/2363#issuecomment-278498852
var https = require('https');

// This is from the original comment.  I dont' really know the format
// that this is stored in, so I'm going to leave it here.  This should
// be rewritten at some point.  The comment says that the buffer to
// parse is a DER-encoded ASN.1 structure.  I don't know what that is
// but this does work
function parseSession(buf) {
  return {
    sessionId: buf.slice(17, 17+32).toString('hex'),
    masterKey: buf.slice(51, 51+48).toString('hex')
  };
}

function patchRequest(req) {
  req.once('socket', function(s) {
    s.once('secureConnect', function() {
      var session = parseSession(s.getSession());
      // session.sessionId and session.masterKey should be hex strings
      var id = session.sessionId;
      var key = session.masterKey;
      var logline = 'RSA Session-ID:' + id + 'Master-Key:' + key + '\n';
      var logfile = process.env.SSLKEYLOGFILE;
      if (!logfile) {
        console.log('Missing Environment Variable SSLKEYLOGFILE');
      }
      fs.appendFileSync(logfile, logline);
    });
  });
}

function patchHttpModule (https) {
  var _https = https;
  https.request = function request(options, callback) {
    var req = _http.request(options, callback);
    patchRequest(req);
    return req;
  }
  return https;
}

module.exports = {
  patchRequest: patchRequest,
  patchHttpModule: patchHttpModule,
  https: patchHttpModule(require('https')),
}
