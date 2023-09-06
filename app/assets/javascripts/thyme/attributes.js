/*
  This file wraps up some attributes that are used in the different
  versions of the thyme player.
*/
var thymeAttributes = {

   /* helps to find the annotation that is currently shown in the
      annotation area */
   activeAnnotationId: 0,

   /* when callig the updateMarkers() method this will be used to save an
      array containing all annotations */
   annotations: null,

   /* if the window width (in px) gets below this threshold value, hide the control bar
   (default value) */
   hideControlBarThreshold: {
     x: 850,
     y: 500
   },

   /* a boolean that helps to deactivate all key listeners
      for the time the annotation modal opens and the user
      has to write text into the command box */
   lockKeyListeners: false,

};