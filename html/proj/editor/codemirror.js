/* CodeMirror main module
 *
 * Implements the CodeMirror constructor and prototype, which take care
 * of initializing the editor frame, and providing the outside interface.
 */

// The CodeMirrorConfig object is used to specify a default
// configuration. If you specify such an object before loading this
// file, the values you put into it will override the defaults given
// below. You can also assign to it after loading.
var CodeMirrorConfig = window.CodeMirrorConfig || {};

var CodeMirror = (function(){
  function setDefaults(object, defaults) {
    for (var option in defaults) {
      if (!object.hasOwnProperty(option))
        object[option] = defaults[option];
    }
  }
  function forEach(array, action) {
    for (var i = 0; i < array.length; i++)
      action(array[i]);
  }

  // These default options can be overridden by passing a set of
  // options to a specific CodeMirror constructor. See manual.html for
  // their meaning.
  setDefaults(CodeMirrorConfig, {
    stylesheet: "",
    path: "",
    parserfile: [],
    basefiles: ["Mochi.js", "util.js", "stringstream.js", "select.js", "undo.js", "editor.js"],
    linesPerPass: 15,
    passDelay: 200,
    continuousScanning: false,
    undoDepth: 20,
    undoDelay: 800,
    disableSpellcheck: true,
    width: "100%",
    height: "300px",
    parserConfig: null
  });

  function CodeMirror(place, options) {
    // Use passed options, if any, to override defaults.
    this.options = options = options || {};
    setDefaults(options, CodeMirrorConfig);

    frame = document.createElement("IFRAME");
    frame.style.border = "0";
    frame.style.width = options.width;
    frame.style.height = options.height;
    frame.name = "";
    frame.id = "iframe";
    frame.setAttribute("pid", "");
    frame.setAttribute("new", "");

    // display: block occasionally suppresses some Firefox bugs, so we
    // always add it, redundant as it sounds.
    frame.style.display = "block";

    if (place.appendChild)
      place.appendChild(frame);
    else
      place(frame);

    // Link back to this object, so that the editor can fetch options
    // and add a reference to itself.
    frame.CodeMirror = this;
    this.win = frame.contentWindow;

    // Create an editor (this can't be done the normal way because of Links)
    //frame.CodeMirror.editor = new Editor(frame.CodeMirror.options);

    if (typeof options.parserfile == "string")
      options.parserfile = [options.parserfile];
    var html = ["<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"" + options.stylesheet + "\"/>"];
    forEach(options.basefiles.concat(options.parserfile), function(file) {
      html.push("<script type=\"text/javascript\" src=\"" + options.path + file + "\"></script>");
      });
    html.push("</head><body style=\"border-width: 0;\" class=\"editbox\" spellcheck=\"" +
              (options.disableSpellcheck ? "false" : "true") + "\"><p style=\"font-size: small; font-family: tahoma, verdana, helvetica;\">Create new or load file to begin working.</p></body></html>");

    var doc = this.win.document;

    doc.designMode = "off";
    doc.open();
    doc.write(html.join(""));
    doc.close();
  }

  CodeMirror.prototype = {
    getCode: function() {
      return this.editor.getCode();
    },
    setCode: function(code) {
      this.editor.importCode(code);
    },
    jumpToLine: function(line) {
      this.editor.jumpToLine(line);
      this.win.focus();
    },
    selection: function() {
      return this.editor.selectedText();
    },
    replaceSelection: function(text, focus) {
      this.editor.replaceSelection(text);
      if (focus) this.win.focus();
    },
    getSearchCursor: function(string, fromCursor) {
      return this.editor.getSearchCursor(string, fromCursor);
    }
  };

  CodeMirror.replace = function(element) {
    if (typeof element == "string")
      element = document.getElementById(element);
    return function(newElement) {
      element.parentNode.replaceChild(newElement, element);
    };
  }

  return CodeMirror;
})();