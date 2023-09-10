class EmergencyButton extends Button  {
  
  add() {
    const video = thymeAttributes.video;
    const element = this.element;

    // Event handler for the emergency button
    element.addEventListener('click', function() {
      video.pause();
      $.ajax(Routes.new_annotation_path(), {
        type: 'GET',
        dataType: 'script',
        data: {
          total_seconds: video.currentTime,
          mediumId: thymeAttributes.mediumId
        }
      });
      // When the modal opens, all key listeners must be
      // deactivated until the modal gets closed again
      thymeAttributes.lockKeyListeners = true;
      $('#annotation-modal').on('hidden.bs.modal', function() {
        thymeAttributes.lockKeyListeners = false;
      });
    });
  }

}