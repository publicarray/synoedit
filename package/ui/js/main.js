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
var textArea = document.querySelector('.synoedit .fileContent textarea')
var spinner = document.querySelector('.synoedit .spinner')
var messageText = document.querySelector('.synoedit .messageText')
var actionForm = document.querySelector('.synoedit .action')
var actionBtn = document.querySelector('.synoedit .action .btn')
var appSelector = document.querySelector('.synoedit .appSelect select')
var fileSelector = document.querySelector('.synoedit .fileSelect select')
var fileForm = document.querySelector('.synoedit .fileEditor')
if (typeof CodeMirror === "undefined") {
    textArea.style.opacity = 1
} else {
    CodeMirror.commands.save = function(insance) { // overload save function
        debug("CodeMirror save event", insance)
        insance.save()
        var param = addParameter('app', appSelector.value) + addParameter('file', fileSelector.value) + addParameter('ajax', 'true')
        ajax('POST', 'fileContent='+encodeURIComponent(textArea.value) + param, function() { // insance.getTextArea().value
            displaySuccess('Saved changes!')
        })
    }

    var editor = CodeMirror.fromTextArea(textArea, {
        lineNumbers: true
        // theme: 'monokai'
    });
}

debug(configFiles)

function debug(message, object) {
    if (typeof dev !== 'undefined' && dev) {
        console.log(message, object)
    }
}

function addParameter(key, value) {
    return '&' + key + '=' + value
}

function displayError(message) {
    messageText.style.animation = 'none'
    messageText.classList.remove('success')
    messageText.classList.add('error')
    messageText.offsetHeight //  trigger reflow
    messageText.innerText = message
    messageText.style.animation = null
}

function displaySuccess(message) {
    // Restart Animation
    messageText.style.animation = 'none'
    messageText.classList.remove('error')
    messageText.classList.add('success')
    messageText.offsetHeight //  trigger reflow
    messageText.innerText = message
    messageText.style.animation = null
}

function ajax(method, data, successFunc, handlerFunc) {
    toggleSpinner() // start spinner
    var request = new XMLHttpRequest()
    request.onload = function() {
        if (request.status == 200) {
            debug('ajax response', request)
            response = JSON.parse(request.responseText)
            if (response.status === 0) { // success
                successFunc(response.message, response)
            } else if (response.status === 1) { // error
                console.error('ajax', response)
                displayError(response.message)
            } else {
                console.info(response.status, response.message)
            }

            if (typeof handlerFunc === 'function') {
                handlerFunc(response)
            }
        } else {
            console.error('ajax', response)
            displayError(response.message)
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
            editor.getDoc().setValue(r)
        } else {
            textArea.value = r
        }
    })
}, false)

actionForm.addEventListener('submit', function(e) {
    if (e.preventDefault) e.preventDefault();
    debug('action event', e)
    var param = addParameter('app', appSelector.value)
    debug('params', param)
    ajax('POST', 'action=true' + param, function () {
        displaySuccess('Done!')
    })
}, false)

fileForm.addEventListener('submit', function saveForm (e) {
    if (e && typeof e.preventDefault === 'function') e.preventDefault();
    debug('file content submit event', e)
    var param = addParameter('app', appSelector.value) + addParameter('file', fileSelector.value) + addParameter('ajax', 'true')
    debug('params', param)
    ajax('POST', 'fileContent='+encodeURIComponent(textArea.value) + param, function() {
        displaySuccess("Saved changes!")
    })
}, false)
