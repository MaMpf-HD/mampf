import { Uppy } from "@uppy/core";
import Dashboard from "@uppy/dashboard";
import XHRUpload from "@uppy/xhr-upload";

export function buildUppy({
  target,
  endpoint,
  autoProceed = true,
  allowMultipleFiles = false,
  allowedFileTypes = [],
  maxFileSize = null,
  note = null,
  onBeforeUpload,
}) {
  const restrictions = {};

  if (!allowMultipleFiles) {
    restrictions.maxNumberOfFiles = 1;
  }

  if (allowedFileTypes.length) {
    restrictions.allowedFileTypes = allowedFileTypes;
  }

  if (maxFileSize) {
    restrictions.maxFileSize = maxFileSize;
  }

  const uppy = new Uppy({
    autoProceed,
    allowMultipleUploadBatches: false,
    restrictions,
    onBeforeUpload,
  });

  uppy.use(Dashboard, {
    inline: true,
    target,
    proudlyDisplayPoweredByUppy: false,
    showProgressDetails: true,
    hideUploadButton: autoProceed,
    width: "100%",
    height: 300,
    note,
  });

  uppy.use(XHRUpload, {
    endpoint,
    formData: true,
    fieldName: "file",
    headers: uploadHeaders(),
    getResponseData(xhr) {
      return JSON.parse(xhr.responseText);
    },
  });

  return uppy;
}

export function clearUppyFiles(uppy) {
  uppy.getFiles().forEach(file => uppy.removeFile(file.id));
}

export function extractErrorMessage(error) {
  if (!error) {
    return "";
  }

  if (typeof error === "string") {
    return error;
  }

  return error.message || "";
}

export function joinErrorMessage(prefix, error) {
  const message = extractErrorMessage(error);

  if (!prefix) {
    return message;
  }

  return `${prefix} ${message}`.trim();
}

export function formatBytes(bytes, digits = 2) {
  if (!bytes) {
    return "0 Bytes";
  }

  const unit = 1024;
  const labels = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  const index = Math.floor(Math.log(bytes) / Math.log(unit));

  return `${parseFloat((bytes / unit ** index).toFixed(digits))} ${labels[index]}`;
}

function uploadHeaders() {
  const token = document.querySelector("meta[name='csrf-token']")?.content;
  const headers = { "X-Requested-With": "XMLHttpRequest" };

  if (token) {
    headers["X-CSRF-Token"] = token;
  }

  return headers;
}
