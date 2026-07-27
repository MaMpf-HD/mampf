import { Controller } from "@hotwired/stimulus";

import {
  buildUppy,
  clearUppyFiles,
  formatBytes,
  joinErrorMessage,
} from "~/uploads/uppy_utils";

export default class extends Controller {
  static targets = [
    "dashboard",
    "hiddenInput",
    "permission",
    "permissionField",
    "metadata",
    "noMetadata",
    "removeButton",
    "pendingNotice",
    "uploadedNotice",
    "saveButton",
  ];

  static values = {
    endpoint: String,
    acceptedFileTypes: String,
    maxFileSize: Number,
    failureMessage: String,
    missingConsentMessage: String,
    note: String,
    uploadButtonLabel: String,
  };

  connect() {
    if (!this.hasDashboardTarget || !this.hasHiddenInputTarget) {
      return;
    }

    this.uppy = buildUppy({
      target: this.dashboardTarget,
      endpoint: this.endpointValue,
      autoProceed: false,
      allowedFileTypes: this.acceptedFileTypes(),
      maxFileSize: this.maxFileSizeValue,
      note: this.noteValue || null,
      dashboardLocale: this.dashboardLocale(),
      onBeforeUpload: () => {
        if (this.permissionTarget.checked) {
          return true;
        }

        alert(this.missingConsentMessageValue);
        return false;
      },
    });

    if (this.hasUploadedFile()) {
      this.showUploadedState({ pendingSave: false });
    }
    else {
      this.showChooserState();
    }

    this.uppy.on("file-added", (_file) => {
      this.hiddenInputTarget.value = "";
      this.setDetachValue("false");
      this.showChooserState({ fileSelected: true });
      this.disableSave();
    });

    this.uppy.on("restriction-failed", (_file, error) => {
      this.showError(error.message || error);
    });

    this.uppy.on("upload-error", (_file, error, _response) => {
      this.showError(error);
    });

    this.uppy.on("complete", (result) => {
      if (result.failed.length) {
        this.showError(result.failed[0].error);
        clearUppyFiles(this.uppy);
        return;
      }

      const response = result.successful.at(-1)?.response?.body;

      if (!response) {
        this.showError(this.failureMessageValue);
        clearUppyFiles(this.uppy);
        return;
      }

      this.hiddenInputTarget.value = JSON.stringify(response);
      this.notifyFieldChanged(this.hiddenInputTarget);
      this.metadataTarget.textContent
        = `${response.metadata.filename} (${formatBytes(response.metadata.size)})`;
      this.showUploadedState({ pendingSave: true });
      this.enableSave();
      this.setDetachValue("false");
      clearUppyFiles(this.uppy);
    });
  }

  disconnect() {
    this.uppy?.destroy();
  }

  remove(event) {
    event.preventDefault();
    this.hiddenInputTarget.value = "";
    this.setDetachValue("true");
    this.notifyFieldChanged(this.hiddenInputTarget);
    this.metadataTarget.textContent = "";
    this.showChooserState();
    this.enableSave();
    clearUppyFiles(this.uppy);
  }

  acceptedFileTypes() {
    return this.acceptedFileTypesValue
      .split(",")
      .map(value => value.trim())
      .filter(Boolean);
  }

  dashboardLocale() {
    if (!this.hasUploadButtonLabelValue || !this.uploadButtonLabelValue) {
      return null;
    }

    return {
      strings: {
        uploadXFiles: {
          0: this.uploadButtonLabelValue,
        },
        uploadXNewFiles: {
          0: this.uploadButtonLabelValue,
        },
      },
    };
  }

  disableSave() {
    if (this.hasSaveButtonTarget) {
      this.saveButtonTarget.disabled = true;
    }
  }

  enableSave() {
    if (this.hasSaveButtonTarget) {
      this.saveButtonTarget.disabled = false;
    }
  }

  setDetachValue(value) {
    const detachInput = document.getElementById("submission_detach_user_manuscript");

    if (detachInput) {
      detachInput.value = value;
    }
  }

  notifyFieldChanged(element) {
    if (!element) {
      return;
    }

    element.dispatchEvent(new Event("change", { bubbles: true }));
  }

  hasUploadedFile() {
    return this.hiddenInputTarget.value.trim() !== "" || this.isVisible(this.metadataTarget);
  }

  isVisible(element) {
    return Boolean(element) && getComputedStyle(element).display !== "none";
  }

  showChooserState({ fileSelected = false } = {}) {
    this.show(this.dashboardTarget);
    this.show(this.permissionFieldTarget);
    this.permissionTarget.checked = false;
    this.hide(this.metadataTarget);
    this.show(this.noMetadataTarget, "inline");
    this.hide(this.removeButtonTarget);

    if (fileSelected) {
      this.show(this.pendingNoticeTarget);
    }
    else {
      this.hide(this.pendingNoticeTarget);
    }

    this.hide(this.uploadedNoticeTarget);
  }

  showUploadedState({ pendingSave }) {
    this.hide(this.dashboardTarget);
    this.hide(this.permissionFieldTarget);
    this.permissionTarget.checked = false;
    this.show(this.metadataTarget, "inline");
    this.hide(this.noMetadataTarget);
    this.show(this.removeButtonTarget, "inline-block");
    this.hide(this.pendingNoticeTarget);

    if (pendingSave) {
      this.show(this.uploadedNoticeTarget);
    }
    else {
      this.hide(this.uploadedNoticeTarget);
    }
  }

  show(element, display = "") {
    if (element) {
      element.style.display = display;
    }
  }

  hide(element) {
    if (element) {
      element.style.display = "none";
    }
  }

  showError(error) {
    alert(joinErrorMessage(this.failureMessageValue, error));
  }
}
