import { Controller } from "@hotwired/stimulus";

import {
  buildUppy,
  clearUppyFiles,
  debugLog,
  formatBytes,
  joinErrorMessage,
} from "~/uploads/uppy_utils";

const IMAGE_TYPES = ["image/jpeg", "image/png", "image/gif"];
const CORRECTION_TYPES = [".cc", ".hh", ".m", ".txt", ".mlx", ".zip", ".pdf"];

const CONFIG = {
  "video": {
    autoProceed: true,
    allowedFileTypes: ["video/mp4"],
    maxFileSize: 4 * 1024 * 1024 * 1024,
    onSuccess(controller, response) {
      controller.setText("#video-file", response.metadata.filename);
      controller.setText("#video-size", formatBytes(response.metadata.size));
      controller.show("#video-meta");
      controller.show("#video-preview-area");
      controller.setValue("#medium_detach_video", "false");
      controller.show(controller.warningSelectorValue || "#medium-basics-warning");
      return true;
    },
  },
  "manuscript": {
    autoProceed: true,
    allowedFileTypes: ["application/pdf"],
    maxFileSize: 50 * 1024 * 1024,
    onSuccess(controller, response) {
      if (response.metadata.pages == null) {
        controller.showError(controller.invalidMessageValue);
        return false;
      }

      controller.setText("#manuscript-file", response.metadata.filename);
      controller.setText("#manuscript-size", formatBytes(response.metadata.size));
      controller.setText("#manuscript-pages", `${response.metadata.pages} S`);

      const destinations = document.getElementById("manuscript-destinations");
      const mediumDestinations = document.getElementById("medium-manuscript-destinations");

      if (destinations) {
        destinations.innerHTML = "";
        controller.hide(destinations);
      }

      if (mediumDestinations) {
        mediumDestinations.innerHTML = "";
        controller.hide(mediumDestinations);
      }

      controller.show("#manuscript-meta");
      controller.hide("#manuscript-preview");
      controller.setValue("#medium_detach_manuscript", "false");
      controller.show(controller.warningSelectorValue || "#medium-basics-warning");
      return true;
    },
  },
  "geogebra": {
    autoProceed: true,
    allowedFileTypes: [".ggb", "application/zip"],
    maxFileSize: 1 * 1024 * 1024,
    onSuccess(controller, response) {
      controller.setText("#geogebra-file", response.metadata.filename);
      controller.setText("#geogebra-size", formatBytes(response.metadata.size));
      controller.show("#geogebra-meta");
      controller.setValue("#medium_detach_geogebra", "false");
      controller.show(controller.warningSelectorValue || "#medium-basics-warning");
      return true;
    },
  },
  "image": {
    autoProceed: true,
    allowedFileTypes: IMAGE_TYPES,
    maxFileSize: 10 * 1024 * 1024,
    onSuccess(controller, response, files) {
      const preview = controller.resolve(controller.previewSelectorValue);

      if (preview && files[0]) {
        preview.src = URL.createObjectURL(files[0]);
        controller.show(preview);
      }

      controller.setText("#image-file", response.metadata.filename);
      controller.setText("#image-size", formatBytes(response.metadata.size));
      controller.setText(
        "#image-resolution",
        `${response.metadata.width}x${response.metadata.height}`,
      );
      controller.show("#image-meta");
      controller.hide("#image-none");
      controller.setValue(controller.detachSelectorValue, "false");
      controller.show(controller.warningSelectorValue);
      return true;
    },
  },
  "correction": {
    autoProceed: true,
    allowedFileTypes: CORRECTION_TYPES,
    maxFileSize: 15 * 1024 * 1024,
    onFileAdded(controller) {
      controller.disableSubmitButton();
    },
    onSuccess(controller, response) {
      if (Number(response.metadata.size) === 0) {
        controller.showError(controller.emptyFileMessageValue);
        return false;
      }

      controller.metadataTarget.textContent
        = `${response.metadata.filename} (${formatBytes(response.metadata.size)})`;
      controller.show(controller.metadataTarget, "inline");
      controller.enableSubmitButton();
      return true;
    },
  },
  "bulk-correction": {
    autoProceed: true,
    allowMultipleFiles: true,
    allowedFileTypes: CORRECTION_TYPES,
    maxFileSize: 15 * 1024 * 1024,
    onFileAdded(controller) {
      controller.disableSubmitButton();
      controller.metadataTarget.textContent = "";
    },
    onSuccess(controller, responses) {
      const emptyFile = responses.find(response => Number(response.metadata.size) === 0);

      if (emptyFile) {
        controller.showError(
          `${emptyFile.metadata.filename} ${controller.emptyFileMessageValue}`.trim(),
        );
        controller.metadataTarget.textContent = "";
        return false;
      }

      controller.metadataTarget.textContent
        = `${responses.length} ${controller.metadataTarget.dataset.trUploads || ""}`.trim();
      controller.enableSubmitButton();
      return true;
    },
  },
};

export default class extends Controller {
  static targets = ["dashboard", "hiddenInput", "metadata", "submitButton"];

  static values = {
    kind: String,
    endpoint: String,
    failureMessage: String,
    invalidMessage: String,
    emptyFileMessage: String,
    hiddenInputSelector: String,
    previewSelector: String,
    warningSelector: String,
    detachSelector: String,
    note: String,
  };

  connect() {
    this.config = CONFIG[this.kindValue];
    this.autoUpload = Boolean(this.config?.autoProceed);
    this.uploadPending = false;
    this.hiddenInputElement = this.hasHiddenInputTarget
      ? this.hiddenInputTarget
      : this.resolve(this.hiddenInputSelectorValue);

    if (!this.config || !this.hasDashboardTarget || !this.hiddenInputElement) {
      debugLog(this.kindValue || "unknown", "connect-skipped", {
        hasConfig: Boolean(this.config),
        hasDashboardTarget: this.hasDashboardTarget,
        hasHiddenInput: Boolean(this.hiddenInputElement),
      });
      return;
    }

    debugLog(this.kindValue, "connect", {
      endpoint: this.endpointValue,
      hiddenInputId: this.hiddenInputElement.id,
      autoProceed: this.config.autoProceed,
    });

    this.uppy = buildUppy({
      target: this.dashboardTarget,
      endpoint: this.endpointValue,
      autoProceed: false,
      hideUploadButton: this.autoUpload,
      allowMultipleFiles: this.config.allowMultipleFiles,
      allowedFileTypes: this.config.allowedFileTypes,
      maxFileSize: this.config.maxFileSize,
      note: this.noteValue || null,
      debugLabel: this.kindValue,
    });

    this.uppy.on("file-added", (file) => {
      debugLog(this.kindValue, "file-added", {
        name: file.name,
        type: file.type,
        size: file.size,
      });
      this.hiddenInputElement.value = "";
      this.config.onFileAdded?.(this);
    });

    this.uppy.on("files-added", (files) => {
      debugLog(this.kindValue, "files-added", {
        files: files.map(file => ({ name: file.name, type: file.type, size: file.size })),
        autoUpload: this.autoUpload,
      });

      if (this.autoUpload) {
        this.startUpload("files-added");
      }
    });

    this.uppy.on("upload", (uploadId, files) => {
      debugLog(this.kindValue, "upload-start", {
        uploadId,
        files: files.map(file => ({ name: file.name, type: file.type, size: file.size })),
      });
    });

    this.uppy.on("upload-success", (file, response) => {
      debugLog(this.kindValue, "upload-success", {
        file: { name: file.name, type: file.type, size: file.size },
        response,
      });
    });

    this.uppy.on("restriction-failed", (_file, error) => {
      debugLog(this.kindValue, "restriction-failed", { error });
      this.showError(error.message || error);
    });

    this.uppy.on("upload-error", (file, error, response) => {
      debugLog(this.kindValue, "upload-error", {
        file: file && { name: file.name, type: file.type, size: file.size },
        error,
        response,
      });
      this.showError(error);
    });

    this.uppy.on("complete", (result) => {
      this.uploadPending = false;
      debugLog(this.kindValue, "complete", {
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

      const responses = result.successful
        .map(file => file.response?.body)
        .filter(Boolean);

      if (!responses.length) {
        this.showError(this.failureMessageValue);
        clearUppyFiles(this.uppy);
        return;
      }

      const payload = this.config.allowMultipleFiles ? responses : responses.at(-1);
      const files = result.successful.map(file => file.data);
      const success = this.config.onSuccess?.(this, payload, files);

      if (success === false) {
        debugLog(this.kindValue, "success-handler-returned-false", { payload });
        clearUppyFiles(this.uppy);
        return;
      }

      this.hiddenInputElement.value = JSON.stringify(payload);
      debugLog(this.kindValue, "hidden-input-updated", {
        hiddenInputId: this.hiddenInputElement.id,
        value: this.hiddenInputElement.value,
      });
      this.notifyFieldChanged(this.hiddenInputElement);
      clearUppyFiles(this.uppy);
    });
  }

  disconnect() {
    debugLog(this.kindValue || "unknown", "disconnect");
    this.uppy?.destroy();
  }

  startUpload(reason) {
    if (this.uploadPending) {
      debugLog(this.kindValue, "upload-skip-already-pending", { reason });
      return;
    }

    this.uploadPending = true;
    debugLog(this.kindValue, "upload-requested", { reason });

    this.uppy.upload().catch((error) => {
      this.uploadPending = false;
      debugLog(this.kindValue, "upload-request-failed", { reason, error });
      this.showError(error);
    });
  }

  notifyFieldChanged(element) {
    if (!element) {
      return;
    }

    element.dispatchEvent(new Event("change", { bubbles: true }));
  }

  disableSubmitButton() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true;
      this.submitButtonTarget.classList.add("disabled");
    }
  }

  enableSubmitButton() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false;
      this.submitButtonTarget.classList.remove("disabled");
    }
  }

  resolve(reference) {
    if (!reference) {
      return null;
    }

    if (reference instanceof Element) {
      return reference;
    }

    return document.querySelector(reference);
  }

  show(reference, display = "") {
    const element = this.resolve(reference);

    if (element) {
      element.style.display = display;
    }
  }

  hide(reference) {
    const element = this.resolve(reference);

    if (element) {
      element.style.display = "none";
    }
  }

  setText(reference, text) {
    const element = this.resolve(reference);

    if (element) {
      element.textContent = text || "";
    }
  }

  setValue(reference, value) {
    const element = this.resolve(reference);

    if (element) {
      element.value = value;
    }
  }

  showError(error) {
    this.uploadPending = false;
    debugLog(this.kindValue || "unknown", "show-error", { error });
    alert(joinErrorMessage(this.failureMessageValue, error));
  }
}
