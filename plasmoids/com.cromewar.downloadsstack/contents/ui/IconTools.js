.pragma library

function extOf(name) {
    if (!name)
        return "";
    var i = ("" + name).lastIndexOf(".");
    return i >= 0 ? ("" + name).substring(i + 1).toLowerCase() : "";
}

var IMAGE_EXT = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "svgz",
                 "tif", "tiff", "ico", "avif", "jxl"];

function isImage(name) {
    return IMAGE_EXT.indexOf(extOf(name)) !== -1;
}

// A short, human-readable "kind" for the list view.
function kindOf(name, isDir) {
    if (isDir)
        return "Folder";
    var e = extOf(name);
    if (!e)
        return "File";
    if (isImage(name))
        return e.toUpperCase() + " image";
    switch (e) {
    case "pdf": return "PDF document";
    case "doc": case "docx": case "odt": case "rtf": return "Document";
    case "xls": case "xlsx": case "ods": case "csv": return "Spreadsheet";
    case "ppt": case "pptx": case "odp": return "Presentation";
    case "txt": case "md": case "log": return "Text";
    case "zip": case "tar": case "gz": case "tgz": case "bz2": case "xz":
    case "7z": case "rar": case "zst": return "Archive";
    case "mp3": case "flac": case "wav": case "ogg": case "m4a": case "aac":
    case "opus": return "Audio";
    case "mp4": case "mkv": case "webm": case "avi": case "mov": case "wmv":
        return "Video";
    case "appimage": case "run": case "bin": case "exe": case "msi":
        return "Application";
    case "deb": case "rpm": case "pkg": case "apk": return "Package";
    case "iso": case "img": case "dmg": return "Disk image";
    case "torrent": return "Torrent";
    }
    return e.toUpperCase() + " file";
}

// Map a file to a freedesktop icon name (all present in the Breeze icon theme).
function iconName(name, isDir) {
    if (isDir)
        return "folder";

    switch (extOf(name)) {
    // documents
    case "pdf":            return "application-pdf";
    case "doc": case "docx": case "odt": case "rtf": case "abw":
        return "x-office-document";
    case "xls": case "xlsx": case "ods": case "csv": case "tsv":
        return "x-office-spreadsheet";
    case "ppt": case "pptx": case "odp":
        return "x-office-presentation";
    case "epub": case "mobi": case "azw3": case "djvu":
        return "application-epub+zip";
    case "txt": case "md": case "markdown": case "log": case "nfo":
        return "text-x-generic";
    case "html": case "htm": case "xhtml":
        return "text-html";
    // archives
    case "zip": case "tar": case "gz": case "tgz": case "bz2": case "xz":
    case "zst": case "7z": case "rar": case "lz": case "lzma": case "cab":
        return "application-x-archive";
    case "iso": case "img": case "dmg":
        return "media-optical";
    // audio / video
    case "mp3": case "flac": case "wav": case "ogg": case "oga": case "m4a":
    case "aac": case "opus": case "wma": case "aiff":
        return "audio-x-generic";
    case "mp4": case "mkv": case "webm": case "avi": case "mov": case "wmv":
    case "flv": case "m4v": case "mpg": case "mpeg": case "3gp":
        return "video-x-generic";
    // packages / executables
    case "deb":            return "application-x-deb";
    case "rpm":            return "application-x-rpm";
    case "appimage": case "run": case "bin":
        return "application-x-executable";
    case "exe": case "msi":
        return "application-x-ms-dos-executable";
    case "apk":            return "application-vnd.android.package-archive";
    case "pkg":            return "package-x-generic";
    // code / data
    case "json":           return "application-json";
    case "xml": case "yaml": case "yml": case "toml": case "ini": case "conf":
        return "text-x-generic";
    case "js": case "ts": case "py": case "sh": case "bash": case "zsh":
    case "c": case "cpp": case "h": case "hpp": case "rs": case "go":
    case "java": case "kt": case "rb": case "php": case "pl": case "lua":
        return "text-x-script";
    case "torrent":        return "application-x-bittorrent";
    case "sig": case "asc": case "gpg": case "pem": case "key": case "crt":
        return "application-pgp-signature";
    }
    return "application-octet-stream";
}

// ---------------------------------------------------------------- folder icons
// A folder's custom icon lives in "<folder>/.directory": a desktop-entry/INI file
// with an [Desktop Entry] group and an Icon= key (a themed name like "folder-blue",
// or an absolute path). The read runs in QML via QtCore.Settings (Qt 6.5+ blocks
// XMLHttpRequest GET on local files by default); these helpers do the pure-string
// work and hold a process-wide cache.

// Build the ".directory" file URL from a folder's file:// url.
function directoryFileUrl(folderUrl) {
    var u = "" + (folderUrl || "");
    if (u.length === 0)
        return "";
    return u.replace(/\/+$/, "") + "/.directory";
}

// Turn a raw Icon= value into something Kirigami.Icon.source accepts.
// Freedesktop rule: a value containing '/' is a path, otherwise a themed name.
function resolveIconValue(folderUrl, raw) {
    if (raw === undefined || raw === null)
        return "";
    var v = ("" + raw).trim();
    if (v.length === 0)
        return "";                                   // no value -> generic folder
    if (v.indexOf("/") === -1)
        return v;                                     // themed name -> as-is
    if (v.indexOf("file://") === 0)
        return v;                                     // already a URL
    if (v.charAt(0) === "/")
        return "file://" + v;                         // absolute path
    if (v.charAt(0) === "~")
        return "";                                    // home-relative -> unsupported
    return ("" + folderUrl).replace(/\/+$/, "") + "/" + v;  // relative to the folder
}

// Process-wide cache (persists for the life of the QML engine because this is a
// `.pragma library`). Value = resolved source string; "" means "no custom icon";
// `undefined` (missing key) means "not read yet".
var _folderIconCache = ({});

function cachedFolderIcon(folderUrl) {
    return _folderIconCache["" + folderUrl];
}
function setCachedFolderIcon(folderUrl, src) {
    _folderIconCache["" + folderUrl] = (src === undefined || src === null) ? "" : ("" + src);
}
function clearFolderIconCache() {
    _folderIconCache = ({});
}
