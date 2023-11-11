/**
  This file wraps up some attributes that are used in the different
  versions of the thyme player.

  Most attributes are set to undefined or null and must be
  defined when the player is loaded.
*/
const thymeAttributes = {

  /* Saves a reference on the annotation area. */
  annotationArea: null,

  /* Use this to check if the annotation feature is activated. */
  annotationFeatureActive: false,

  /* When callig the updateMarkers() method this will be used to save an
     array containing all annotations. */
  annotations: null,

  /* Saves a reference on the annotation manager */
  annotationManager: null,

  /* A list with all the chapters of the current video. */
  chapters: null,

  /* Saves a reference on the chapter manager. */
  chapterManager: null,

  /* If the window width (in px) gets below this threshold value, hide the control bar
  (default value). */
  hideControlBarThreshold: {
    x: 850,
    y: 500
  },

  /* Saves a reference on the interactive area. */
  interactiveArea: null,

  /* A boolean that helps to deactivate all key listeners
     for the time the annotation modal opens and the user
     has to write text into the command box. */
  lockKeyListeners: false,

  /* Saves the ID of the HTML element to which annotations are appended. */
  markerBarId: undefined,

  /* When loading a player, it should save the medium id in this field for later use
     in different files. */
  mediumId: undefined,

  /* Saves a reference on the metadata manager. */
  metadataManager: null,

  /* Saves a reference on the video's seek bar. */
  seekBar: undefined,

  /* Saves a reference on the video itself */
  video: undefined,

};
