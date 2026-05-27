import { Controller } from "@hotwired/stimulus";

import {
  buildUppy,
  clearUppyFiles,
  debugLog,
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
      debugLog("submission", "connect-skipped", {
        hasDashboardTarget: this.hasDashboardTarget,
        hasHiddenInputTarget: this.hasHiddenInputTarget,
      });
      return;
    }

    debugLog("submission", "connect", {
      endpoint: this.endpointValue,
      hiddenInputId: this.hiddenInputTarget.id,
      acceptedFileTypes: this.acceptedFileTypes(),
      maxFileSize: this.maxFileSizeValue,
    });

    this.uppy = buildUppy({
      target: this.dashboardTarget,
      endpoint: this.endpointValue,
      autoProceed: false,
      allowedFileTypes: this.acceptedFileTypes(),
      maxFileSize: this.maxFileSizeValue,
      note: this.noteValue || null,
      dashboardLocale: this.dashboardLocale(),
      onBeforeUpload: () => {
        debugLog("submission", "before-upload", {
          permissionChecked: this.permissionTarget.checked,
        });

        if (this.permissionTarget.checked) {
          return true;
        }

        alert(this.missingConsentMessageValue);
        return false;
      },
      debugLabel: "submission",
    });

    if (this.hasUploadedFile()) {
      this.showUploadedState({ pendingSave: false });
    }
    else {
      this.showChooserState();
    }

    this.uppy.on("file-added", (file) => {
      debugLog("submission", "file-added", {
        name: file.name,
        type: file.type,
        size: file.size,
      });
      this.hiddenInputTarget.value = "";
      this.setDetachValue("false");
      this.showChooserState({ fileSelected: true });
      this.disableSave();
    });

    this.uppy.on("upload", (uploadId, files) => {
      debugLog("submission", "upload-start", {
        uploadId,
        files: files.map(file => ({ name: file.name, type: file.type, size: file.size })),
      });
    });

    this.uppy.on("upload-success", (file, response) => {
      debugLog("submission", "upload-success", {
        file: { name: file.name, type: file.type, size: file.size },
        response,
      });
    });

    this.uppy.on("restriction-failed", (_file, error) => {
      debugLog("submission", "restriction-failed", { error });
      this.showError(error.message || error);
    });

    this.uppy.on("upload-error", (file, error, response) => {
      debugLog("submission", "upload-error", {
        file: file && { name: file.name, type: file.type, size: file.size },
        error,
        response,
      });
      this.showError(error);
    });

    this.uppy.on("complete", (result) => {
      debugLog("submission", "complete", {
        successful: result.successful.map(file => ({
          name: file.name,
          response: file.response,
        })),
        failed: result.failed.map(file => ({
          name: file.name,
          error: file.error,
        })),
      });

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
      debugLog("submission", "hidden-input-updated", {
        hiddenInputId: this.hiddenInputTarget.id,
        value: this.hiddenInputTarget.value,
      });
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
    debugLog("submission", "disconnect");
    this.uppy?.destroy();
  }

  remove(event) {
    event.preventDefault();
    debugLog("submission", "remove-clicked", {
      hiddenInputId: this.hiddenInputTarget.id,
      previousValue: this.hiddenInputTarget.value,
    });
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
    debugLog("submission", "show-error", { error });
    alert(joinErrorMessage(this.failureMessageValue, error));
  }
}
