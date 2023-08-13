var Selecting = false; // used for other scripts (draggable.js etc.)
let lastElems = []; // current Elements used in selection
let constElems = []; // Used for deselecting, not referenced by lastElems
let nums = []; // elements for mouse selecting
let numElems = 0; // keep track of number of active elements

let firstVX = -1; // first X coord for mouse click (selection)
let firstVY = -1; // first Y coord for mouse click (selection)
let firstElem = null; // cyan box on selection

let isMousePressed = false;

document.addEventListener('mousedown', (event) => {
    numElems++;
    if (firstVX!==-1&&event.button === 0) {
        Selecting = true;
        isMousePressed = true;
        setTimeout(()=>{
            if(isMousePressed){
                const startPosX = event.clientX;
                const startPosY = event.clientY;
                
                firstElem = document.createElement('div');
                document.body.appendChild(firstElem);
                firstElem.classList.add('select-box');
                firstElem.style.top = startPosY + 'px';
                firstElem.style.left = startPosX + 'px';
                
                firstVX = startPosX;
                firstVY = startPosY;
        
                document.addEventListener('mousemove', SelectByMove);
            }
        }, 150);
    };
});

document.addEventListener('mouseup', (event) => {
    if (event.button === 0) {
        Selecting = false
        isMousePressed = false;
        firstElem&&firstElem.remove();
        firstElem=null;
        numElems--;
        if(numElems<=0){
            StopSelect();
        }
    }
});

function SelectByMove(e) {
    if (!isMousePressed||!firstElem) return; // Return if mouse button is not pressed and/or box is not created
    let difX = e.clientX - firstVX;
    let difY = e.clientY - firstVY;
    firstElem.style.width = difX + 'px';
    firstElem.style.height = difY + 'px';
    nums.forEach(elem => {
        if (IsPointInsideIBox(elem.cX, elem.cY, firstVX, firstVY, difX, difY)) {
            if(elem.DOM.classList.contains('select-selected'))return;
            toggleSelection(elem.DOM);
        } else if(!e.shiftKey) {
            if(!elem.DOM.classList.contains('select-selected'))return;
            toggleSelection(elem.DOM);
        }
    });
};

function IsPointInsideIBox(pX, pY, fX, fY, dX, dY) { // Check center points pX and pY are inside box fX, fY, dX, dY;
    const boxStartX = fX;
    const boxStartY = fY;
    const boxEndX = fX + dX;
    const boxEndY = fY + dY;

    return pX >= boxStartX && pX <= boxEndX && pY >= boxStartY && pY <= boxEndY;
};

function StartSelect(elements = [], r) {
    StopSelect();
    numElems = 1;
    elements.forEach(e => {
        const elem = e.DOM ? e.DOM : e;
        elem.addEventListener('click', toggleSelection);
        const bcr = elem.getBoundingClientRect();
        nums.push({cX: bcr.left+(bcr.right-bcr.left)/2, cY: bcr.top+(bcr.bottom-bcr.top)/2, DOM: elem});
    });
    lastElems = elements;
    lastElems.forEach(elem=>{
        constElems.push({...elem});
    });
    firstVX = r.clientX - 10;
    firstVY = r.clientY - 10;
    document.addEventListener('mousemove', SelectByMove);
};

function toggleSelection(e=this) {
    e=e.target?e.target.parentNode:e;
    if(e.classList.contains('select-selected')){
        numElems--;
        e.classList.toggle('select-selected');
        if(numElems===0)StopSelect();
        return;
    } else {
        numElems++;
        e.classList.toggle('select-selected');
    };
};

function StopSelect() {
    constElems.forEach(e => {
        let elem = e.DOM ? e.DOM : e;
        elem.removeEventListener('click', toggleSelection);
        elem.classList.remove('select-selected');
    });
    document.removeEventListener('mousemove', SelectByMove);
    firstElem&&firstElem.remove();
    firstElem=null;
    firstVX=-1;
    constElems=[];
};

function SelectRetrieveSelected() {
    const selected = [];
    lastElems.forEach(e => {
        let elem = e.DOM ? e.DOM : e;
        if (elem.classList.contains('select-selected')) {
            selected.push(e);
        }
    });
    return selected;
};