/* 
    It was written by me, all for those pesky x,y dragging lists! 
    At least it's responsive... I hope.
*/

let [x,y] = [0,0]
let moved = false;
let free = null;
let shadowElement = null;

document.addEventListener('mouseup', ()=>{
    if(free)free.classList.remove('drag-priority');
    free=null;
});

function MoveMouseElement() {
    const container = free.parentNode;
    const bcr = container.getBoundingClientRect();
    const offsetX = x - bcr.x - free.getBoundingClientRect().width / 2;
    const offsetY = y - bcr.y - 10;
    const maxX = bcr.width - free.getBoundingClientRect().width;
    const maxY = bcr.height - free.getBoundingClientRect().height;
    const adjustedX = Math.min(Math.max(offsetX, 0), maxX);
    const adjustedY = Math.min(Math.max(offsetY, 0), maxY);

    free.style.transform = `translate(${adjustedX}px, ${adjustedY}px)`;
};

document.addEventListener('mousemove', (e)=>{
    [x,y]=[e.clientX,e.clientY];
    moved = true;
    if(free){
        MoveMouseElement();
    };
});


function DragElement(elem,parent) {
    if(free)free.classList.remove('drag-priority');
    free=parent===2?elem.taget.parentNode.parentNode:parent?elem.target.parentNode:elem.target?elem.target:elem;
    if(free)free.classList.add('drag-priority');
    MoveMouseElement();
};

function EnsureDraggable() {
    if(shadowElement)return;
    shadowElement = document.createElement('div');
    shadowElement.classList.add('shadow-element');
    shadowElement.style.display = 'none';
    document.body.append(shadowElement);
};

class Draggable {
    constructor(elements={},x=false) {
        this.elements = elements;
        this.elements.forEach(elem=>{
            elem.addEventListener('mousedown', this.StartDragging.bind(this));
        });
        document.addEventListener('mouseup', this.EndDragging.bind(this));
        document.addEventListener('blur', this.EndDragging.bind(this));
        this.priorityx = 0;
        this.priorityy = 0;
        this.currentList = [];
        this.currentElem = [];
        this.isX = x;
        this.dragging = false;
        this.lastElem;
        this.interval;
    };
    StartDragging(e) {
        this.dragging=true;
        setTimeout(()=>{
            if(!this.dragging)return;
            this.lastElem = e.srcElement;
            this.Update();
            DragElement(shadowElement);
            shadowElement.style.display = 'block';
            this.interval = setInterval(()=>{
                if(this.dragging){
                    if(moved){
                        moved=false;
                        this.isX ?
                        this.CompareX(this.currentList, this.priorityx, x) :
                        this.CompareY(this.currentList, this.priorityy, y);
                    };
                } else {
                    this.EndDragging();
                };
            },50);
        }, 150);
    };
    CompareY(list, priority, current) {
        const priorityIndex = list.indexOf(priority);
        if(priorityIndex===-1)return;
        const prevElement = this.currentElem[list[priorityIndex - 1]];
        const nextElement = this.currentElem[list[priorityIndex + 1]];
        if (current < priority && prevElement && current <= prevElement.getBoundingClientRect().y) {
            prevElement.parentNode.insertBefore(this.currentElem[priority], prevElement);
            this.Update();
        } else if (current > priority && nextElement && current >= nextElement.getBoundingClientRect().y) {
            nextElement.parentNode.insertBefore(this.currentElem[priority], nextElement.nextSibling);
            this.Update();
        };
    };
    CompareX(list, priority, current) {
        const priorityIndex = list.indexOf(priority);
        if (priorityIndex === -1) return;
        const prevElement = this.currentElem[list[priorityIndex - 1]];
        const nextElement = this.currentElem[list[priorityIndex + 1]];
        if (current < priority && prevElement && current <= prevElement.getBoundingClientRect().left) {
            prevElement.parentNode.insertBefore(this.currentElem[priority], prevElement);
            this.Update();
        } else if (current > priority && nextElement && current >= nextElement.getBoundingClientRect().right) {
            nextElement.parentNode.insertBefore(this.currentElem[priority], nextElement.nextSibling);
            this.Update();
        };
    };
    EndDragging() {
        this.dragging=false;
        shadowElement.style.display = 'none';
        if(!this.interval)return;
        clearInterval(this.interval);
        this.interval = null;
    };
    Update() {
        if(!this.lastElem)return;
        const elem = this.lastElem;
        const data = elem.getBoundingClientRect();
        if(!this.isX)this.priorityy = Math.floor(data.y+data.height);
        if(this.isX)this.priorityx = Math.floor(data.x+data.width);
        this.currentList = [];
        this.currentElem = [];
        this.elements.forEach(elem=>{
            const bcr = elem.getBoundingClientRect();
            const num = this.isX&&Math.floor(bcr.x+data.width)||Math.floor(bcr.y+data.height);
            this.currentElem[num]=elem;
            this.currentList.push(num);
        });
        this.currentList.sort();
    };
    AddToList(elem) {
        this.elements.push(elem);
        elem.addEventListener('mousedown', this.StartDragging.bind(this));
    };
    RemoveFromList(elem) {
        const index = this.elements.indexOf(elem);
        if(index === -1)return;
        this.elements.splice(index,1);
    };
};
