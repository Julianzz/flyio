// since the lib is async I wrote the functions in the order
// they are executed to give a bit of an overview


function errorsonly(error) {
  if (error) {
    alert('error: ' + error);
  };
};

function errorsorcontent(error, content) {
  if (error) {
    alert('error: ' + error);
  } else if (content) {
    alert('content: ' + content);
    console.log( content )
  };
};

function handler(error, content) {
    if (!error) {
        for (var name in content['DAV:']) {
            console.log(name);
            console.log(content['DAV:'][name].toXML());
            console.log(content['DAV:'].properties.getcontenttype.nodeName);
            console.log(content.properties);
        };
    };
}

function myhandler(status, statusstring, content, headers) {
    if (content) {
        if (status != '200' && status != '204') {
            if (status == '207') {
                alert('not going to show multi-status ' +
                        'here...');
            };
            alert('Error: ' + statusstring);
        } else {
            alert('Content: ' + content);
        };
    };
};


function runTests() {
  var fs = new davlib.DavFS();
  fs.initialize("127.0.0.1",7001 );
  //fs.mkDir('/filelist/foo/', errorsonly);
  fs.write('/filelist/foo/bar.txt', 'some content', errorsonly);
  //fs.read('/filelist/foo/bar.txt', errorsorcontent);
  //fs.remove('/filelist/foo/', errorsonly);
  
  fs.listDir("/filelist/foo/",errorsorcontent );
  //fs.getProps("/filelist/foo",handler );
  
  /*var dc = new davlib.DavClient();
  dc.initialize('127.0.0.1',7001);

  // create a directory
  dc.MKCOL('/filelist/foo', handler);

  // create a file and save some contents
  dc.PUT('/filelist/foo/bar.txt', 'baz?', myhandler);

  // load and alert it (alert happens in the handler)
  dc.GET('/filelist/foo/bar.txt', myhandler);
  dc.GET('/filelist/foo/', myhandler);
  */
};