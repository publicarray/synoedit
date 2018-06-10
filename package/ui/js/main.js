require('codemirror/mode/toml/toml')
require('codemirror/mode/xml/xml')
require('codemirror/mode/yaml/yaml')
require('codemirror/mode/nginx/nginx')

require('codemirror/addon/search/search')
require('codemirror/addon/search/searchcursor')
require('codemirror/addon/dialog/dialog')

require('codemirror/addon/edit/closebrackets')
require('codemirror/addon/edit/closetag')
require('codemirror/addon/edit/continuelist')
require('codemirror/addon/edit/matchtags')
require('codemirror/addon/edit/trailingspace')

require('codemirror/addon/comment/comment')
require('codemirror/addon/comment/continuecomment')

var CodeMirror = require('codemirror/lib/codemirror')

var textArea = document.querySelectorAll('.synoedit textarea')[0]
if (typeof CodeMirror === "undefined") {
    textArea.style.opacity = 1
} else {
    CodeMirror.fromTextArea(textArea, {
        lineNumbers: true
        // theme: 'monokai'
    });
}
