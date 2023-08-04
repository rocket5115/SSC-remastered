// M2 Form (Options)

var [form,wait,formcb] = [undefined,false,undefined];

function CreateSceneDropdownForm(x,y,cb,data) {
    wait=true;
    if(form)form.remove();
    formcb=cb;
    form = document.createElement('div');
    form.innerHTML = data?data:InnerForm;
    form.classList.add('scene-form');
    form.style.transform = `translate(${x-15}px, ${y-15}px)`;
    form.addEventListener('mouseleave', function(e) {
        RemoveSceneDropdownForm();
    });
    $('body').append(form);
};

function RemoveSceneDropdownForm() {
    if(form)form.remove();
    form=undefined;
    formcb=undefined;
};

function SelectedFormOption(...data) {
    if(formcb){
        formcb(...data);
    };
};

// Accept Form (text, checkbox, list ...)

var [formElement,formCB] = [];

function CreateNewForm(data,cb) {
    if(formElement)formElement.remove();
    if(formCB)formCB=undefined;
    if(cb)formCB=cb;
    formElement = document.createElement('div');
    formElement.classList.add('form');
    let ret = "";
    for(let i=0;i<data.length;i++){
        if(data[i].type!='list'){
            ret=ret+OptionsInner[data[i].type].replace('$NAME',data[i].name).replace('$VALUE',data[i].type!='checkbox'?data[i].default:data[i].default?'checked':'');
        } else {
            let rest = "";
            data[i].data.forEach(elem=>{
                rest=rest+`<option value="${elem.value?elem.value:elem.name}">${elem.name}</option>`;
            });
            ret=ret+OptionsInner[data[i].type].replace('$NAME',data[i].name).replace('$ID',data[i].default?data[i].default:data[i].name).replace('$VALUE',rest);
        };
    };
    ret=ret+'<div><button onclick="AcceptForm(this)">Accept</button><button onclick="CancelForm(this)">Cancel</button></div>';
    formElement.innerHTML = ret;
    $('body').append(formElement);
    return formElement;
};

function AcceptForm(button) {
    let e = button.parentNode.parentNode;
    let ret = {};
    e.querySelectorAll('div').forEach(elem=>{
        let select = elem.querySelector('select');
        if(select) {
            ret[select.id]=select.value?select.value:select.options[select.selectedIndex].textContent;
        } else {
            if(elem.querySelector('button'))return;
            ret[elem.querySelector('span').textContent]=elem.querySelector('input[type="text"]')?.value||elem.querySelector('input[type="checkbox"]').checked;
        }
    });
    if(formCB)formCB(ret);
    formCB=undefined;
    e.remove();
};

function CancelForm(button) {
    button.parentNode.parentNode.remove();
    formElement=undefined;
    formCB=undefined;
};