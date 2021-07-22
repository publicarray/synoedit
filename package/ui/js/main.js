var textArea = document.querySelector('.synoedit .fileContent textarea')
var spinner = document.querySelector('.synoedit .spinner')
var model = document.querySelector('.synoedit .model')
var modelText = document.querySelector('.synoedit .modelText')
var messageText = document.querySelector('.synoedit .messageText')
var actionForm = document.querySelector('.synoedit .action')
var actionBtn = document.querySelector('.synoedit .action .btn')
var appSelector = document.querySelector('.synoedit .appSelect select')
var fileSelector = document.querySelector('.synoedit .fileSelect select')
var fileForm = document.querySelector('.synoedit .fileEditor')
var editor

if (typeof CodeMirror === "undefined") {
    textArea.style.opacity = 1
} else {
    CodeMirror.modeURL = "codemirror/mode/%N/%N.js";
    CodeMirror.commands.save = function(instance) { // overload save function
        debug("CodeMirror save event", instance)
        instance.save()
        var param = addParameter('app', appSelector.value) + addParameter('file', fileSelector.value) + addParameter('ajax', 'true')
        ajax('POST', 'fileContent='+encodeURIComponent(textArea.value) + param, function() { // instance.getTextArea().value
            displaySuccess('Saved changes!')
        })
    }

    editor = CodeMirror.fromTextArea(textArea, {
        lineNumbers: true,
        keyMap: 'sublime',
        autoCloseBrackets: true,
        matchBrackets: true,
        matchTags: true,
        // showTrailingSpace: true,
        // continueComments: true,
        showCursorWhenSelecting: true,
        // theme: 'monokai'
    })
}

debug(configFiles)

// Activate with: dev = true
function debug(message, object) {
    if (typeof dev !== 'undefined' && dev) {
        console.log(message, object)
    }
}

function changeMode(filename) {
    // https://codemirror.net/demo/loadmode.html
    var mode = CodeMirror.findModeByFileName(filename)
    if (mode && mode.mode) {
        if (mode.mode === "null") {
            debug("changeMode-fallback: ", 'toml')
            mode.mode = 'toml'
        }
        editor.setOption("mode", mode.mode)
        CodeMirror.autoLoadMode(editor, mode.mode)
        debug("changeMode: ", mode)
    }
}

// const addGetParameter = (function addGetParameterInit (key, value) {
//     this.urlParams = new URLSearchParams(window.location.search)
//     this.baseUrl = [location.protocol, '//', location.host, location.pathname].join('')
//     this.go () => {
//         document.location = this.baseUrl + this.urlParams.toString()
//     }
//     this.string() => {
//         this.urlParams.toString()
//     }
//     return (key, value) => {
//         this.urlParams.set(key, value)
//     }
// })()

function addParameter(key, value) {
    return '&' + key + '=' + value
}

function displayModel(message, status) {
    model.style.display = 'block'
    if (status === 1) {
        model.style.color = '#f00'
    } else {
        model.style.color = '#000'
    }
    modelText.innerText = message
}
function hideModel() {
    model.style.display = 'none'
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
            if (response.model === true) {
                displayModel(response.message, response.status)
            }
            else if (response.status === 0) { // success
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
            console.error('ajax', request)
            displayError("Oh no! A fatal error has occurred!")
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

function updateEditorContent(newText) {
    if (typeof editor !== 'undefined') {
        editor.getDoc().setValue(newText)
    } else {
        textArea.value = newText
    }
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
    changeMode(e.target.value)
    ajax('GET', param, function(responseText) {
        updateEditorContent(responseText)
    })
}, false)

actionForm.addEventListener('submit', function(e) {
    if (e.preventDefault) e.preventDefault();
    debug('action event', e)
    var param = addParameter('app', appSelector.value) + addParameter('ajax', 'true')
    debug('params', param)
    ajax('POST', 'action=true' + param, function (responseText) {
        // Update editor content if viewing the file currently being modified
        var modifiedFile = configFiles[appSelector.value].Action.OutputFile
        if (modifiedFile !== '' && fileSelector.value == modifiedFile) {
            updateEditorContent(responseText)
        }
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
