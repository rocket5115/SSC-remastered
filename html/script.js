const DraggableScenes = new Draggable([]); //Initiate draggable.js class for dragging(ordering) scenes

function ChangeSceneDropdownState(e) { //hiding/showing content of scenes
    let parent = e.parentNode.parentNode;
    if(parent.classList.contains('hide-content')){
        parent.classList.remove('hide-content');
        e.style.animation = 'rotate-to-show 0.5s ease-in-out forwards';
    } else {
        parent.classList.add('hide-content');
        e.style.animation = 'rotate-to-hide 0.5s ease-in-out forwards';
    };
};

function SendEvent(name, data) {
    Config.debug&&console.log("INTERNAL: "+name+":",JSON.stringify(data));
    document.dispatchEvent(new CustomEvent(name, {detail: data}));
};

const post = (cb,data) => {
    Config.debug&&console.log("POST: "+cb+":",JSON.stringify(data));
    try { // for testing on Browser
        return $.post('https://'+GetParentResourceName()+'/'+cb,data?JSON.stringify(data):"{}");
    } catch(err) {
        return {then:()=>{}} // Also for browser
    };
};

document.addEventListener('contextmenu', function(e) {
    e.preventDefault();
    setTimeout(()=>{
        if(!wait){
            RemoveSceneDropdownForm();
        };
        wait=false;
    },10);
});

document.addEventListener('keydown', function(e) {
    if(e.key==='Escape'){
        post('nuioff',{});
    };
});

const Scenes = {};
const QuickAccess = {};

function CreateSceneInstance(id,skip) {
    if(Scenes['Scene: '+id])return;
    id=String(id);
    const element = document.createElement('div');
    element.classList.add('scene-wrapper');
    element.innerHTML = InnerScene.replace('$ID',id);
    const newTable = {
        id: id,
        children: [],
        DOM: element,
        drag: new Draggable([])
    }
    Scenes['Scene: '+id]=newTable;
    document.querySelector('.list').append(element);
    SendEvent('scene-created', {id: newTable.id});
    !skip&&post('scene_create', {id: newTable.id})
    element.querySelector('.wrapper-title').addEventListener('dblclick', (e)=>{//double click for quick hide/show content
        ChangeSceneDropdownState(e.target.parentNode.querySelector('div'));
    });
    if(id!=0){ //leave Scene with ID 0 as a default scene
        element.querySelector('span').addEventListener('contextmenu', function(e) {
            CreateSceneDropdownForm(e.clientX,e.clientY,(ret)=>{
                RemoveSceneDropdownForm();
                if(ret==='delete'){
                    MoveChildrenToScene(Scenes['Scene: '+newTable.id], Scenes['Scene: 0']);
                    DraggableScenes.RemoveFromList(Scenes['Scene: '+newTable.id].DOM);
                    Scenes['Scene: '+newTable.id].DOM.remove();
                    SendEvent('scene-deleted', {id: newTable.id});
                    post('scene_delete', {id: newTable.id});
                    delete(Scenes['Scene: '+newTable.id]);
                } else if(ret==='change'){
                    CreateNewForm([
                        {name: 'id', default: id, type: 'text'}
                    ], (r)=>{
                        if(Scenes['Scene: '+r.id]) {
                            SendError('Scene already exists!');
                        } else {
                            Scenes['Scene: '+r.id]=Scenes['Scene: '+newTable.id];
                            SendEvent('scene-renamed', {old: newTable.id, new: r.id});
                            delete(Scenes['Scene: '+newTable.id]);
                            newTable.id = r.id;
                            Scenes['Scene: '+r.id].children.forEach(elem=>{
                                elem.data.scene_id=r.id;
                            });
                            element.querySelector('span').querySelector('span').textContent = 'Scene: '+r.id;
                        };
                    });
                };
            });
        });
    };
    id!=0&&DraggableScenes.AddToList(element);
    return element
};

let gfd = 0;

function MoveChildrenToScene(from, to) { // send children nodes from one DOM&Object to another
    const wrapper = to.DOM.querySelector('.wrapper-content');
    for(let i=0;i<from.children.length;i++) {
        from.children[i].data.scene_id=to.id;
        wrapper.appendChild(from.children[i].DOM);
        to.children.push(from.children[i]);
        from.drag.RemoveFromList(from.children[i].DOM);
        to.drag.AddToList(from.children[i].DOM);
        SendEvent('entity-moved', {from: from.id, to: to.id, entity: from.children[i].data.name})
        post('entity_move_scene', {from: from.id, to: to.id, entity: from.children[i].data.name});
        delete(from.children[i]);
    };
};

function MoveSingleChildToScene(element, from, to) {
    const index = from.children.findIndex((child) => child.DOM === element);
    if (index !== -1) {
        const wrapperTo = to.DOM.querySelector('.wrapper-content');
        wrapperTo.appendChild(element);
        from.children[index].data.scene_id = to.id;
        to.children.push(from.children[index]);
        SendEvent('entity-moved', {from: from.id, to: to.id, entity: from.children[index].data.name});
        post('entity_move_scene', {from: from.id, to: to.id, name: from.children[index].data.name});
        from.children.splice(index, 1);
        from.drag.RemoveFromList(element);
        to.drag.AddToList(element);
    };
};

function GetSceneNames(except={}) {
    const data = [];
    Object.keys(Scenes).forEach(k=>{
        if(except.hasOwnProperty(k))return;
        data.push({name: k, value: k.substring(7,k.length)});
    });
    return data;
};

function GetEntitiesNames(except={}) {
    const data = [];
    Object.keys(Scenes).forEach(k=>{
        Scenes[k].children.forEach(entity=>{
            if(except.hasOwnProperty(entity.data.name))return;
            data.push({name: entity.data.name, value: entity.data.name, scene_id: entity.data.scene_id});
        });
    });
    return data;
};

function SetQuickElement(table) {
    QuickAccess[table.name] = table;
};

function GetQuickElement(name) {
    return QuickAccess[name]
};

function ChangeQuickElement(o,n) {
    if(QuickAccess[o])QuickAccess[n]=QuickAccess[o];
    delete(QuickAccess[o]);
};

function AddSceneElement(id, type, name) {
    if(!Scenes['Scene: '+id])return;
    const element = document.createElement('div');
    element.classList.add('wrapper-element');
    element.innerHTML = InnerSceneElement.replace('$TYPE',type===1?'user':type===2?'car':'box').replace('$ID', name);
    Scenes['Scene: '+id].DOM.querySelector('.wrapper-content').append(element);
    const newTable = {
        type: type,
        name: name,
        scene_id: id,
        DOM: element
    };
    SetQuickElement(newTable);
    SendEvent('entity-added', {id: id, name: name});
    Scenes['Scene: '+id].children.push({DOM: element, data: newTable});
    Scenes['Scene: '+id].drag.AddToList(element);
    element.addEventListener('contextmenu', function(e) {
        wait=true;
        CreateSceneDropdownForm(e.clientX,e.clientY,(ret)=>{
            RemoveSceneDropdownForm();
            if(ret==='focus'){
                WorkspaceFocusOnElement(newTable.name);
            } else if(ret==='go_to'){
                post('go_to_entity', {name: newTable.name})
            } else if(ret==='delete'){
                newTable.DOM.remove();
                const children = Scenes['Scene: '+newTable.scene_id].children;
                for(let i=0;i<children.length;i++){
                    if(children[i].data===newTable){
                        children.splice(i,1);
                        break;
                    };
                };
                SendEvent('removed-entity', {name: newTable.name});
                post('remove_entity', {name: newTable.name});
                delete(newTable);
            } else if(ret==='select'){
                StartSelect(Scenes['Scene: '+newTable.scene_id].children, e);
                newTable.DOM.classList.add('select-selected');
            } else if(ret==='stop2') {
                StopSelect();
            } else if(ret==='change2') {
                const elems = SelectRetrieveSelected();
                if(elems.length===0){
                    SendError('No Elements Selected!');
                    return;
                };
                const wCAT = GetSceneNames({["Scene: "+newTable.scene_id]:true});
                if(wCAT.length===0){
                    SendError('No Other Scenes Available!');
                    return;
                };
                CreateNewForm([{
                    name: 'New Scene',
                    default: 'id',
                    type: 'list',
                    data: wCAT
                }], (e)=>{
                    const id = newTable.scene_id;
                    elems.forEach(elem=>{
                        MoveSingleChildToScene(elem.DOM, Scenes['Scene: '+id], Scenes['Scene: '+e.id]);
                    });
                    StopSelect();
                });
            } else if(ret==='send2') {
                const elems = SelectRetrieveSelected();
                if(elems.length===0)return;
                CreateNewForm([
                    {name: 'name', default: 'new-scene', type: 'text'}
                ], (e)=>{
                    if(Scenes['Scene: '+e.name])return;
                    CreateSceneInstance(e.name);
                    const id = newTable.scene_id;
                    elems.forEach(elem=>{
                        MoveSingleChildToScene(elem.DOM, Scenes['Scene: '+id], Scenes['Scene: '+e.name]);
                    });
                    StopSelect();
                });
            } else if(ret==='delete2') {
                const elems = SelectRetrieveSelected();
                if(elems.length===0)return;
                const id = newTable.scene_id;
                elems.forEach(elem=>{
                    elem.DOM.remove();
                    const children = Scenes['Scene: '+id].children;
                    for(let i=0;i<children.length;i++){
                        if(children[i].DOM===elem.DOM){
                            children.splice(i,1);
                            break;
                        };
                    };
                    SendEvent('removed-entity', {name: elem.data.name});
                    post('remove_entity', {name: elem.data.name});
                });
            };
        },element.classList.contains('select-selected')?InnerSelectForm:InnerChildForm);
    });
    return element;
};

$(document).ready(function(){
    EnsureDraggable(); //draggable.js <shadowElement>
    EnsureWorkspace(); //workspace.js
    EnsureNotifications(); //notifications.js
    //Ensure List Element(Scenes,events)
    CreateSceneInstance(0,true);
    //CreateSceneInstance(1,true);
    /*AddSceneElement(1,1,'ok');
    AddSceneElement(1,1,'ok2');
    AddSceneElement(1,1,'ok3');*/
    document.querySelector('.list').addEventListener('contextmenu', function(e) {
        if(!wait){
            CreateSceneDropdownForm(e.clientX, e.clientY, (ret)=>{
                RemoveSceneDropdownForm();
                if(ret==='create'){
                    CreateNewForm([
                        {name: 'id', default: 'new-scene', type: 'text'}
                    ], (r)=>{
                        if(Scenes['Scene: '+r.id]) {
                            SendError('Scene already exists!');
                        } else {
                            CreateSceneInstance(r.id);
                        };
                    });
                };
            },InnerSceneForm);
        };
    });
});

function AddEntity(type) {
    CreateNewForm(Options[type], (e)=>{post('spawn_entity', {type: type, model: e.model, mission: e.mission, network: e.network, door: e.door})});
};

function SearchEntity() {
    post('nuioff',{});
    post('search_entity', {});
};

function GetRelativePositionInPercent(cx,cy,rx,ry) {
    return [(cx / rx).toFixed(2),(cy / ry).toFixed(2)];
};

window.addEventListener('message', function (event) {
    let data = event.data;
    Config.debug&&console.log('MSG: '+data.type+":",JSON.stringify(data));
    if(data.type==='show') {
        if(data.show){
            document.querySelector('.G_Container').style.display = 'grid';
        } else {
            document.querySelector('.G_Container').style.display = 'none';
            SetCMenuDisplay(false);
        };
    } else if(data.type==='new_entity'){
        AddSceneElement(data.scene||0,data._type,data.entity);
    } else if(data.type==='new_scene'){
        CreateSceneInstance(data.name)
    } else if(data.type==='remove_scenes'){
        Object.keys(Scenes).forEach(key=>{
            Scenes[key].children.forEach(child=>{
                child.DOM.remove();
                SendEvent('removed-entity', {name: child.data.name});
            });
            Scenes[key].DOM.remove();
            SendEvent('scene-deleted', {id: key.replace('Scene: ','')});
            delete(Scenes[key]);
        });  
        CreateSceneInstance(0,true);
    } else if(data.type==='notification'){
        AddNotification(data.options?data.options:data); // done for my screw up in Lua part
    } else if(data.type==='update_entity'){
        WorkspaceUpdateData(data.data);
    } else if(data.type==='information'){
        SetInformation(data.data);
    } else if(data.type==='d_information'){
        RemoveInformation();
    } else if(data.type==='info_update_slider'){
        InfoSetSlider(data.name, data.value);
        if(data.ids) {
            InfoSetVars(data.ids);
        };
    } else if(data.type==='remove_entity'){
        const newTable = GetQuickElement(data.entity);
        newTable.DOM.remove();
        const children = Scenes['Scene: '+newTable.scene_id].children;
        for(let i=0;i<children.length;i++){
            if(children[i].data===newTable){
                children.splice(i,1);
                break;
            };
        };
        SendEvent('removed-entity', {name: newTable.name});
        post('remove_entity', {name: newTable.name});
        delete(newTable);
    } else if(data.type==='event'){
        SendEvent(data.name, {...data.data})
    };
});

document.addEventListener('workspace-move-all', (e)=>{
    const [from,to] = [e.detail.from,e.detail.to];
    MoveChildrenToScene(Scenes['Scene: '+from],Scenes['Scene: '+to]);
});

document.addEventListener('workspace-move-single', (e)=>{
    const [from,to,id] = [e.detail.from,e.detail.to,e.detail.entity];
    MoveSingleChildToScene(GetQuickElement(id)?.DOM,Scenes['Scene: '+from],Scenes['Scene: '+to]);
});

document.addEventListener('workspace-created-scene', (e)=>{
    CreateSceneInstance(e.detail.id);
});

document.addEventListener('workspace-deleted-scene', (e)=>{
    const id = e.detail.id;
    DraggableScenes.RemoveFromList(Scenes['Scene: '+id].DOM);
    Scenes['Scene: '+id].DOM.remove();
    SendEvent('scene-deleted', {id: id});
    delete(Scenes['Scene: '+id]);
});

document.addEventListener('workspace-entity-added', (e)=>{
    const [id,scene] = [e.detail.entity, e.detail.id];
    if(!QuickAccess.hasOwnProperty(id))return;
    if(QuickAccess[id].scene_id===scene)return;
    SendEvent('workspace-move-single', {from: QuickAccess[id].scene_id, to: scene, entity: id});
});