
var cordova = require('cordova');

var backgroundvideo = {
    start : function(filename, camera, successFunction, errorFunction) {
    	camera = camera || 'back';
        cordova.exec(successFunction, errorFunction, "backgroundvideo","start", [filename, camera]);
    },
        show : function(successFunction, errorFunction) {
        cordova.exec(successFunction, errorFunction, "backgroundvideo","show", []);
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
