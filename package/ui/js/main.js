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
var production = false
var textArea = document.querySelectorAll('.synoedit .fileContent textarea')[0]
var spinner = document.querySelectorAll('.synoedit .spinner')[0]
var successMessage = document.querySelectorAll('.synoedit .success')[0]
var errorMessage = document.querySelectorAll('.synoedit .error')[0]
var actionForm = document.querySelectorAll('.synoedit .action')[0]
var actionBtn = document.querySelectorAll('.synoedit .action .btn')[0]
var appSelector = document.querySelectorAll('.synoedit .appSelect select')[0]
var fileSelector = document.querySelectorAll('.synoedit .fileSelect select')[0]
var fileForm = document.querySelectorAll('.synoedit .fileEditor')[0]
if (typeof CodeMirror === "undefined") {
    textArea.style.opacity = 1
} else {
    CodeMirror.commands.save = function(insance) { // overload save function
        debug("CodeMirror save event", insance)
        insance.save()
        var param = addParameter('app', appSelector.value) + addParameter('file', fileSelector.value) + addParameter('ajax', 'true')
        ajax('POST', 'fileContent='+encodeURIComponent(textArea.value) + param, function() { // insance.getTextArea().value
            // restart fade animation
            successMessage.style.animation = 'none';
            successMessage.offsetHeight //  trigger reflow
            successMessage.innerText = 'Saved changes!'
            successMessage.style.animation = null
        })
    }

    var editor = CodeMirror.fromTextArea(textArea, {
        lineNumbers: true
        // theme: 'monokai'
    });
}

// function setGetParameter (key, value) {
//     var baseUrl = [location.protocol, '//', location.host, location.pathname].join('')
//     var param = '?' + key + '=' + value
//     document.location = baseUrl+param
// }
function debug(message, object) {
    if (production === false) {
        console.log(message, object)
    }
}

function addParameter(key, value) {
    return '&' + key + '=' + value
}

function ajax (method, data, successFunc) {
    toggleSpinner() // start spinner
    var request = new XMLHttpRequest()
    request.onload = function() {
        if (request.status >= 200 && request.status < 400) {
            debug('ajax response', request)
            successFunc(request)
        } else {
            console.error(request.status, request.responseText)
            errorMessage.style.animation = 'none';
            errorMessage.offsetHeight //  trigger reflow
            errorMessage.innerText = request.responseText
            errorMessage.style.animation = null
        }
        toggleSpinner()
    }
    request.onerror = function() {
        console.error(request.status, request.responseText)
        errorMessage.style.animation = 'none';
        errorMessage.offsetHeight //  trigger reflow
        errorMessage.innerText = "Something went wrong :'("
        errorMessage.style.animation = null
        toggleSpinner()
    }
    if (method === 'POST') {
        request.open(method, '', true)
        request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
        request.send(data)
    } else {
        request.open(method, '?ajax=true'+data, true)
        request.send()
    }
}

function toggleSpinner () {
    spinner.style.visibility = (spinner.style.visibility === 'visible') ? 'hidden' : 'visible'
}

function getFiles (appName) {
    return configFiles[appName].Files || []
}

function getActionLabel (appName) {
   return configFiles[appName].Action.Label || ""
}

appSelector.addEventListener('change', function(e) {
    var appName = e.target.value;
    // remove all items
    while (fileSelector.hasChildNodes()) {
        fileSelector.removeChild(fileSelector.lastChild)
    }

    // create first empty option
    var option = new Option('')
    fileSelector.appendChild(option)

    // populate options
    var files = getFiles(appName)
    debug(files)
    for (var i = files.length - 1; i >= 0; i--) {
        var option = new Option(files[i], files[i])
        fileSelector.appendChild(option)
    }

    // update Action button label
    var actionBtnLabel = getActionLabel(appName)
    debug(actionBtnLabel)
    if (actionBtnLabel != "") {
        actionBtn.value = actionBtnLabel
        actionBtn.style.display = 'block'
        actionBtn.disabled = false
    } else {
        actionBtn.style.display = 'none'
        actionBtn.disabled = true
    }
}, false)

fileSelector.addEventListener('change', function(e) {
    var param = addParameter('app', appSelector.value) + addParameter('file', e.target.value)
    ajax('GET', param, function(r) {
        if (typeof editor !== 'undefined') {
            editor.getDoc().setValue(r.responseText)
        } else {
            textArea.value = r.responseText
        }
    })
}, false)

actionForm.addEventListener('submit', function(e) {
    if (e.preventDefault) e.preventDefault();
    debug('action event', e)
    var param = addParameter('app', appSelector.value)
    debug('params', param)
    ajax('POST', 'action=true' + param, function () {
        // restart fade animation
        successMessage.style.animation = 'none';
        successMessage.offsetHeight //  trigger reflow
        successMessage.innerText = 'Done!'
        successMessage.style.animation = null
    })
}, false)

fileForm.addEventListener('submit', function saveForm (e) {
    if (e && typeof e.preventDefault === 'function') e.preventDefault();
    debug('file content submit event', e)
    var param = addParameter('app', appSelector.value) + addParameter('file', fileSelector.value) + addParameter('ajax', 'true')
    debug('params', param)
    ajax('POST', 'fileContent='+encodeURIComponent(textArea.value) + param, function() {
        // restart fade animation
        successMessage.style.animation = 'none';
        successMessage.offsetHeight //  trigger reflow
        successMessage.innerText = 'Saved changes!'
        successMessage.style.animation = null
    })
}, false)
