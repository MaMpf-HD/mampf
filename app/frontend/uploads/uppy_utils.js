import { Uppy } from "@uppy/core";
import Dashboard from "@uppy/dashboard";
import XHRUpload from "@uppy/xhr-upload";
import de_DE from "@uppy/locales/lib/de_DE";
import en_US from "@uppy/locales/lib/en_US";

export function buildUppy({
  target,
  endpoint,
  autoProceed = true,
  hideUploadButton = autoProceed,
  allowMultipleFiles = false,
  allowedFileTypes = [],
  maxFileSize = null,
  note = null,
  onBeforeUpload,
  dashboardLocale,
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

  const uppyOptions = {
    autoProceed,
    allowMultipleUploadBatches: false,
    locale: uppyLocale(),
    restrictions,
  };

  if (typeof onBeforeUpload === "function") {
    uppyOptions.onBeforeUpload = onBeforeUpload;
  }

  const uppy = new Uppy(uppyOptions);

  const dashboardOptions = {
    inline: true,
    target,
    proudlyDisplayPoweredByUppy: false,
    showProgressDetails: true,
    hideUploadButton,
    width: "100%",
    height: 300,
    note,
  };

  if (dashboardLocale) {
    dashboardOptions.locale = dashboardLocale;
  }

  uppy.use(Dashboard, dashboardOptions);

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

function uppyLocale() {
  const locale = document.body?.dataset?.locale || "en";

  if (locale.startsWith("de")) {
    return de_DE;
  }

  return en_US;
}
