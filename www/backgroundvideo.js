
var cordova = require('cordova');

var backgroundvideo = {
    show : function(filename, camera, successFunction, errorFunction) {
    	camera = camera || 'back';
        cordova.exec(successFunction, errorFunction, "backgroundvideo","show", [filename, camera]);
    },
        start : function(successFunction, errorFunction) {
        cordova.exec(successFunction, errorFunction, "backgroundvideo","start", []);
    },
        hide : function(successFunction, errorFunction) {
        cordova.exec(successFunction, errorFunction, "backgroundvideo","hide", []);
    },
    stop : function(successFunction, errorFunction) {
        cordova.exec(successFunction, errorFunction, "backgroundvideo","stop", []);
    }
};

module.exports = backgroundvideo;
window.Plugin.backgroundvideo = backgroundvideo;
