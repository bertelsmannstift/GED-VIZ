/* jslint node: true, globalstrict: true */
/* global phantom, WebPage */

'use strict';

var system = require('system');

/* Performance measuring */
var time = {};
time.start = Date.now();

/* Input arguments */
var directory      = system.args[1];
var presentationId = system.args[2];
var baseUrl        = system.args[3];
var locale         = system.args[4];
var size           = system.args[5];
var showTitles     = system.args[6] === '1';
var showLegend     = system.args[7] === '1';
var keyframeIndex  = system.args[8];

var protectionTimer;

if (presentationId === null || presentationId === '') {
  console.log(
    'Usage: phantomjs script/render_presentation.js ' +
    'DIR PRESENTATION_ID BASE_URL SIZE SHOW_TITLES SHOW_LEGEND KEYFRAME_INDEX'
  );
  phantom.exit(1);
}

/* Functions */

var getViewportSize = function (size) {
  var s;
  if (size === 'large') {
    s = {width: 800, height: 600};
  } else if (size === 'medium') {
    s = {width: 520, height: 390};
  } else if (size === 'small') {
    s = {width: 300, height: 225};
  } else if (size === 'thumb') {
    s = {width: 150, height: 150};
  } else {
    console.error('Unknown size ' + size);
    phantom.exit(1);
  }
  if (showLegend) {
    s.width += 260;
  }
  return s;
};

var getURL = function () {
  var url = baseUrl + '/render/' + presentationId;
  if (keyframeIndex) {
    url += '/' + keyframeIndex;
  }
  url += '?lang=' + locale;
  url += '&size=' + size;
  if (showTitles) {
    url += '&show_titles=1';
  }
  if (showLegend) {
    url += '&show_legend=1';
  }

  return url;
};

var optionsString = function () {
  return [
    locale,
    size,
    showTitles ? 1 : 0,
    showLegend ? 1 : 0
  ].join('_');
};

var getFilename = function (keyframeDrawn) {
  keyframeDrawn = parseInt(keyframeDrawn, 10);

  if (keyframeDrawn < 10) {
    keyframeDrawn = '000' + keyframeDrawn;
  } else if (keyframeDrawn < 100) {
    keyframeDrawn = '00' + keyframeDrawn;
  } else if (keyframeDrawn < 1000) {
    keyframeDrawn = '0' + keyframeDrawn;
  }

  return directory + '/keyframe_' + keyframeDrawn + '_' +
    optionsString() + '.png';
};

var emergencyExit = function () {
  console.error('TIMEOUT! EMERGENCY EXIT.');
  console.log('---- render_presentation.js Aborted ----');
  phantom.exit(1);
};

var resetProtectionTimer = function () {
  clearTimeout(protectionTimer);
  protectionTimer = setTimeout(emergencyExit, 15000);
};

var createPage = function () {
  var page = new WebPage();

  page.viewportSize = getViewportSize(size);
  page.paperSize = {
    width:  page.viewportSize.width  + 'px',
    height: page.viewportSize.height + 'px',
    border: '0'
  };

  return page;
};

var pageOpened = function () {
  time.opened = Date.now();
  console.log('Opened. Waiting for callback…');
  resetProtectionTimer();
};

var done = function () {
  console.log('Finished rendering.');
  time.done = Date.now();
  console.log('start\t '  , time.start                 );
  console.log('open\t+'   , time.open - time.start     );
  console.log('opened\t+' , time.opened - time.open    );
  console.log('1st cb\t+' , time.callback - time.opened);
  console.log('done\t+'   , time.done - time.callback  );
  console.log('total\t '  , time.done - time.start     );
  console.log('---- render_presentation.js Success ----');
  phantom.exit(0);
};

var onCallback = function (page, data) {
  time.callback = time.callback || Date.now();
  console.log('Received callback. keyframeDrawn:', data.keyframeDrawn, 'finished:', data.finished);
  if (data.keyframeDrawn !== null) {
    resetProtectionTimer();
    var pngFile = getFilename(data.keyframeDrawn);
    page.render(pngFile);
    console.log('Saved PNG:', pngFile);
    //var pdfFile = directory + '/keyframe_' + data.keyframeDrawn + '.pdf';
    //page.render(pdfFile);
  }
  if (data.finished) {
    done();
  } else {
    console.log('Call renderAgent.drawNext');
    resetProtectionTimer();
    page.evaluate(function() {
      console.log('Call renderAgent.drawNext');
      window.renderAgent.drawNext();
    });
  }
};

var onError = function(msg, trace) {
  var msgStack = ['ERROR: ' + msg];
  if (trace) {
    msgStack.push('TRACE:');
    trace.forEach(function(t) {
      msgStack.push(' -> ' + t.file + ': ' + t.line + (t['function'] ? ' (in function "' + t['function'] + '")' : ''));
    });
  }
  console.error(msgStack.join('\n'));
};

var onConsoleMessage = function(msg) {
  console.log('CONSOLE: ' + msg);
};

var start = function () {
  console.log('---- render_presentation.js ----');
  console.log(
    'directory:', directory,
    '\npresentationId:', presentationId,
    '\nlocale:', locale,
    '\nsize:', size,
    '\nshowTitles:', showTitles,
    '\nshowLegend:', showLegend,
    '\nkeyframeIndex:', keyframeIndex
  );
  // Setup Page
  var page = createPage();
  time.open = Date.now();
  console.log('Open', getURL());
  resetProtectionTimer();
  page.open(getURL(), pageOpened);
  page.onCallback = function (data) {
    onCallback(page, data);
  };
  page.onError = onError;
  page.onConsoleMessage = onConsoleMessage;
};

// Start the engine
start();