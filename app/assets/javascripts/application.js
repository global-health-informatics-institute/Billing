// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= //require jquery
//=// require jquery_ujs
//= require turbolinks
// require_tree .

function toggleTab(tab){

    var tabs = document.getElementsByClassName("tab-active");
    for (var e=0; e < tabs.length; e++){

        document.getElementById(tabs[e].id+"Tab").className="tab-content invisible"
        tabs[e].className = "tab";

    }

    tab.className="tab-active"
    document.getElementById(tab.id+"Tab").classList.remove("invisible")

}

function showModal() {
    // Get the modal
    var modal = document.getElementById('myModal');

    modal.style.display = "block";


}

function hideModal(){
    var modal = document.getElementById('myModal');
    modal.style.display = "none";
}

function initializeCollapsible() {
    var acc = document.getElementsByClassName("collapsible-summary");
    var i;

    for (i = 0; i < acc.length; i++) {
        acc[i].onclick = function() {
            this.classList.toggle("active");
            var panel = this.nextElementSibling;
            if (panel.style.maxHeight){
                panel.style.maxHeight = null;
            } else {
                panel.style.maxHeight = panel.scrollHeight + "px";
            }
        }
    }

}

function localize(amount)
{
    return "MWK " + parseFloat(amount).toFixed(2).toString();
}

function delocalize(value)
{
    return value.replace("MWK", "").trim();
}
function getCharButtonSetID(character,id){
    return '<button onMouseDown="press(\''+character+'\');" class="keyboardButton" id="'+id+'">' +"<span style='width:32px'>"+character+"</span>"+ "</button>";
}
function getButtonString(id,string){
    return "<button \
                            onMouseDown='press(this.id);' \
                            class='keyboardButton' \
                            id='"+id+"'>"+
        string +
        "</button>";
}

function getButtons(chars){
    var buttonLine = "";
    for(var i=0; i<chars.length; i++){
        character = chars.substring(i,i+1)
        buttonLine += getCharButtonSetID(character,character)
    }
    return buttonLine;
}

function showAlphaKeypad(){
    document.getElementById("keypad").style.height = "280";
    keyboard.innerHTML= getButtons("0123456789") + "</br>"
    keyboard.innerHTML+= getButtons("QWERTYUIOP") + "</br>"
    keyboard.innerHTML+= getButtons("ASDFGHJKL:") + "</br>"
    keyboard.innerHTML+= getButtons("ZXCVBNM,.?")
    keyboard.innerHTML+= getButtonString('backspace','<span>Bksp</span>')
    keyboard.innerHTML+= getButtonString('Space','<span>Space</span>')
    keyboard.innerHTML+= getButtonString('clear','<span>Clear</span>')
//     keyboard.innerHTML+= getButtonString('cancel','<span>Cancel</span>')
}

function showKeyboard(){
    console.log("show keyboard")
    key = document.getElementById("keypad")
    if(key.style.display == 'none' || key.style.display == ""){
        key.style.display = "inline";
        return
    }

    key.style.display = "none";
}

function press(pressedChar){
    switch (pressedChar) {
        case 'backspace':
            search.value = search.value.substring(0,search.value.length-1);
            search_box.fnFilter(search.value)
            return;
        case 'Space':
            search.value+= " "
            search_box.fnFilter(search.value)
            return
        case 'clear':
            search.value = ""
            search_box.fnFilter(search.value)
            return
        case 'cancel':
            search.value = ""
            showKeyboard();
            return
        case 'slash':
            search.value+= "/"
            search_box.fnFilter(search.value)
            return
        case 'dash':
            search.value+= "-"
            search_box.fnFilter(search.value)
            return
        case 'abc':
            showAlphaKeypad();
            return
    }
    search.value+= pressedChar
    search_box.fnFilter(search.value)
}
function getBrowserHeight() {
    var intH = 0;
    var intW = 0;

    if(typeof window.innerWidth  == 'number' ) {
        intH = window.innerHeight;
        intW = window.innerWidth;
    }
    else if(document.documentElement && (document.documentElement.clientWidth || document.documentElement.clientHeight)) {
        intH = document.documentElement.clientHeight;
        intW = document.documentElement.clientWidth;
    }
    else if(document.body && (document.body.clientWidth || document.body.clientHeight)) {
        intH = document.body.clientHeight;
        intW = document.body.clientWidth;
    }

    return { width: parseInt(intW), height: parseInt(intH) };
}

function setLayerPosition(background, main) {
    var shadow = document.getElementById(background);
    var question = document.getElementById(main);

    var bws = getBrowserHeight();
    shadow.style.width = bws.width + "px";
    shadow.style.height = bws.height + "px";

    question.style.left = parseInt((bws.width - 350) / 11);
    question.style.top = parseInt((bws.height - 200) / 15);

    shadow = null;
    question = null;
}

function showLayer(background, main) {
    setLayerPosition(background, main);

    var shadow = document.getElementById(background);
    var question = document.getElementById(main);

    shadow.style.display = "block";
    question.style.display = "block";

    shadow = null;
    question = null;
}

function hideLayer(background,main) {
    var shadow = document.getElementById(background);
    var question = document.getElementById(main);

    shadow.style.display = "none";
    question.style.display = "none";

    shadow = null;
    question = null;
}

function confirmAction(actionUrl, type)
{
    showLayer('shadow', 'question')
    if (type == 'FORM')
    {
        document.confirmingForm.action = actionUrl;
        document.getElementById("bttnYes").setAttribute("onmousedown", "document.confirmingForm.submit();hideLayer('shadow', 'question')");
    }
    else
    {
        document.getElementById("bttnYes").setAttribute("onmousedown", "window.location='"+actionUrl + "'")
    }
    // document.getElementById("message").innerHTML = message;
}

