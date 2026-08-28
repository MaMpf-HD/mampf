import { Uppy } from "@uppy/core";
import Dashboard from "@uppy/dashboard";
import XHRUpload from "@uppy/xhr-upload";
import de_DE from "@uppy/locales/lib/de_DE";
import en_US from "@uppy/locales/lib/en_US";

export function buildUppy({
  target,
  endpoint,
  intent,
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
    height: 90,
    singleFileFullScreen: false,
    note,
  };

  if (dashboardLocale) {
    dashboardOptions.locale = dashboardLocale;
  }

  uppy.use(Dashboard, dashboardOptions);

  uppy.use(XHRUpload, {
    endpoint: localizedEndpoint(endpoint),
    formData: true,
    fieldName: "file",
    headers: uploadHeaders(intent),
    // A rejected file stays rejected; only a broken connection is worth
    // another round through the malware scanner.
    shouldRetry: xhr => xhr.status === 0 || xhr.status >= 500,
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

  return serverExplanation(error.request) || error.message || "";
}

/**
 * Uppy reports every rejected upload as a network error, so the reason the
 * server gave -- infected file, scanner down, not allowed -- has to be read off
 * the response itself.
 */
function serverExplanation(xhr) {
  if (!xhr?.getResponseHeader("content-type")?.startsWith("text/plain")) {
    return "";
  }

  return xhr.responseText?.trim() || "";
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

/** The scan gate answers in the locale it is asked in, not the user's. */
function localizedEndpoint(endpoint) {
  const locale = document.body?.dataset?.locale;
  const url = new URL(endpoint, window.location.origin);

  if (!locale || url.searchParams.has("locale")) {
    return endpoint;
  }

  url.searchParams.set("locale", locale);

  return url.pathname + url.search;
}

function uploadHeaders(intent) {
  const token = document.querySelector("meta[name='csrf-token']")?.content;
  const headers = { "X-Requested-With": "XMLHttpRequest" };

  if (token) {
    headers["X-CSRF-Token"] = token;
  }

  if (intent) {
    headers["X-Upload-Intent"] = intent;
  }

  return headers;
}

// Uppy's German says "Sie"; MaMpf says "Du" everywhere. Only the strings a
// MaMpf upload can actually produce are rewritten -- camera, companion and
// url-import belong to plugins we do not use.
const DE_INFORMAL = {
  youCanOnlyUploadFileTypes: "Du kannst nur folgende Dateitypen hochladen: %{types}",
  youCanOnlyUploadX: {
    0: "Du kannst nur eine Datei hochladen",
    1: "Du kannst nur %{smart_count} Dateien hochladen",
  },
  youHaveToAtLeastSelectX: {
    0: "Du musst mindestens eine Datei auswählen",
    1: "Du musst mindestens %{smart_count} Dateien auswählen",
  },
  selectX: {
    0: "Wähle %{smart_count}",
    1: "Wähle %{smart_count}",
  },
  noFilesFound: "Du hast hier keine Dateien oder Ordner",
};

function uppyLocale() {
  const locale = document.body?.dataset?.locale || "en";

  if (locale.startsWith("de")) {
    return { strings: { ...de_DE.strings, ...DE_INFORMAL }, pluralize: de_DE.pluralize };
  }

  return en_US;
}
