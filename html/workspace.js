let workspace;
let workspaceMain;
let workspaceHeader;
let workspaceLast;
let workspaceLastActive;
const workspace_cat = {};
const workspace_ent = {};
const workspaceDrag = new Draggable([],true);
let toWait = false;

function GetCategoriesNames(except={}) {
    const data = [];
    Object.keys(workspace_cat).forEach(k=>{
        if(except.hasOwnProperty(k))return;
        data.push({name: k, value: k});
    });
    return data;
};

function EnsureWorkspace() {
    if(workspace)return;
    workspace = document.querySelector('.workspace');
    workspaceHeader = workspace.querySelector('.workspace-header');
    workspaceMain = workspace.querySelector('.workspace-main');
    workspaceHeader.addEventListener('contextmenu', (e)=>{
        setTimeout(()=>{
            if(!toWait){
                CreateSceneDropdownForm(e.clientX-10, e.clientY-10, (ret)=>{
                    RemoveSceneDropdownForm();
                    if(ret==='add'){
                        CreateNewForm([
                            {name: 'name', default: 'new-scene', type: 'text'}
                        ], (r)=>{
                            AddWorkspaceHeaderElement(r.name);
                        });
                    };
                },InnerWorkspaceHeaderForm);
            };
            toWait=false;
        },10)
    });
    workspaceMain.addEventListener('contextmenu', (e)=>{
        setTimeout(()=>{
            if(toWait)return;
            CreateSceneDropdownForm(e.clientX-10, e.clientY-10, (ret)=>{
                RemoveSceneDropdownForm();
                if(ret==='add'){
                    const wENT = GetEntitiesNames(workspace_ent);
                    if(wENT.length===0){
                        SendError('All Entities Currently In Use!');
                        return;
                    };
                    CreateNewForm([{
                        name: 'add entity',
                        default: 'id',
                        type: 'list',
                        data: wENT
                    }], (e)=>{
                        let id = 0;
                        if(!workspaceLast){
                            for(let i=0;i<wENT.length;i++){
                                if(wENT[i].name==e.id){
                                    if(!workspace_cat[wENT[i].name])break;
                                    id = wENT[i].scene_id;
                                    break;
                                };
                            };
                        } else {
                            id=workspaceLast.id;
                        };
                        SendEvent('workspace-entity-added', {entity: e.id, id: id});
                        AddWorkspaceCategoryElement(e.id, id);
                    });
                };
            },InnerWorkspaceForm);
        },10);
    });
};

function AddWorkspaceHeaderElement(name) {
    if(workspace_cat.hasOwnProperty(name))return;
    const element = document.createElement('div');
    element.classList.add('workspace-header-element');
    element.textContent = name;
    name!=0&&workspaceDrag.AddToList(element);
    workspace.querySelector('.workspace-header').append(element);
    const newHeaderElement = {
        id: name,
        DOM: element,
        container: CreateWorkspaceCategoryContainer(name),
        children: []
    };
    workspace_cat[name]=newHeaderElement;
    SendEvent('workspace-created-scene', {id: name});
    element.addEventListener('contextmenu', (e)=>{
        toWait=true;
        CreateSceneDropdownForm(e.clientX-10, e.clientY-10, (ret)=>{
            RemoveSceneDropdownForm();
            if(ret==='delete'){
                ChangeWorkspaceElementsCategory(newHeaderElement.id,'0');
                SendEvent('workspace-deleted-scene', {id: newHeaderElement.id});
                newHeaderElement.container.remove();
                newHeaderElement.DOM.remove();
                delete(newHeaderElement);
            } else if(ret==='send') {
                const wCAT = GetCategoriesNames({[newHeaderElement.id]:true});
                if(wCAT.length===0){
                    SendError('No Other Categories Available!');
                    return;
                };
                CreateNewForm([{
                    name: 'add entity',
                    default: 'id',
                    type: 'list',
                    data: wCAT
                }], (e)=>{
                    ChangeWorkspaceElementsCategory(newHeaderElement.id,e.id)
                });
            } else if(ret==='change') {
                CreateNewForm([{
                    name: 'name',
                    default: newHeaderElement.id,
                    type: 'text'
                }], (e)=>{
                    if(e.name==newHeaderElement.id)return;
                    workspace_cat[e.name]=newHeaderElement;
                    delete(workspace_cat[newHeaderElement.id]);
                    newHeaderElement.id=e.name;
                    newHeaderElement.children.forEach(elem=>{
                        elem.id=e.name;
                    });
                    newHeaderElement.DOM.textContent=e.name;
                    newHeaderElement.container.id=e.name;
                });
            };
        },name==0?InnerWorkspaceHeaderElementFormMain:InnerWorkspaceHeaderElementForm);
    });
    element.addEventListener('click', (e)=>{
        if(workspaceLast)workspaceLast.classList.add('workspace-hide');
        if(workspaceLastActive)workspaceLastActive.classList.remove('workspace-active');
        if(workspaceLastActive==e.target){workspaceLastActive=undefined;return;};
        e.target.classList.add('workspace-active');
        workspaceLast=document.getElementById(e.target.textContent);
        workspaceLastActive=e.target;
        workspaceLast.classList.remove('workspace-hide');
    });
};

function CreateWorkspaceCategoryContainer(name) {
    const container = document.createElement('div');
    container.id = name;
    container.classList.add('workspace-main-category');
    container.classList.add('workspace-hide');
    workspaceMain.append(container);
    return container;
};

function AddWorkspaceCategoryElement(name, id) {
    if(workspace_ent.hasOwnProperty(name)||!workspace_cat.hasOwnProperty(id))return;
    const element = document.createElement('div');
    element.classList.add('workspace-main-category-element');
    element.classList.add('hide-content');
    element.innerHTML = CategoryElementHTML.replace('$NAME',name);
    const newCategory = {
        name: name,
        id: id,
        DOM: element
    };
    const header = element.querySelector('.category-element-header');
    header.querySelector('span').addEventListener('mousedown', ()=>{
        DragElement(header.parentElement);
    });
    header.addEventListener('contextmenu', (e)=>{
        toWait = true;
        CreateSceneDropdownForm(e.clientX-10, e.clientY-10, (ret)=>{
            RemoveSceneDropdownForm();
            toWait=false;
            if(ret==='change') {
                const wCAT = GetCategoriesNames({[newCategory.id]:true});
                if(wCAT.length===0){
                    SendError('No Other Categories Available!');
                    return;
                };
                CreateNewForm([{
                    name: 'add entity',
                    default: 'id',
                    type: 'list',
                    data: wCAT
                }], (e)=>{
                    SendEvent('workspace-move-single', {from:newCategory.id, to:e.id, entity:newCategory.name});
                    ChangeWorkspaceSingleElementCategory(newCategory.id,e.id,newCategory,workspace_ent[newCategory.name],newCategory.name);
                });
            } else if(ret==='delete') {
                const children = workspace_cat[newCategory.id].children;
                for(let i=0;i<children.length;i++){
                    if(children[i]===newCategory){
                        newCategory.DOM.remove();
                        children.splice(i,1);
                        break;
                    };
                };
                delete(workspace_ent[newCategory.name]);
                delete(newCategory);
            };
        },CategoryElementOptions);
    });
    const arrow = header.querySelector('.wrapper-hide-show');
    header.addEventListener('dblclick', ()=>{
        ChangeSceneDropdownState(arrow);
    });
    const main = element.querySelector('.category-element-main')
    main.innerHTML=InnerCategoryElementHTML.replace('$NAME', name);
    SetupDynamicConfigElement(main);
    workspace_ent[name] = newCategory;
    workspace_cat[id].container.append(element);
    workspace_cat[id].children.push(newCategory);
};

function ChangeWorkspaceElementsCategory(from,to) {
    if(!workspace_cat.hasOwnProperty(from) || !workspace_cat.hasOwnProperty(to))return;
    SendEvent('workspace-move-all', {from:from, to:to});
    workspace_cat[from].children.forEach(elem=>{
        elem.id = to;
        workspace_cat[to].container.append(elem.DOM);
        workspace_cat[to].children.push(elem);
    });
};

function ChangeWorkspaceSingleElementCategory(from,to,elem,e_id) {
    if (!workspace_cat.hasOwnProperty(from) || !workspace_cat.hasOwnProperty(to) || from==to) return;
    if(elem===undefined){
        AddWorkspaceCategoryElement(to,e_id);
        return;
    };
    const fromCategory = workspace_cat[from];
    fromCategory.children = fromCategory.children.filter((element) => element !== elem);
    elem.id = to;
    const toCategory = workspace_cat[to];
    toCategory.children.push(elem);
    toCategory.container.append(elem.DOM);
};

function WorkspaceFocusOnElement(name) {
    const ent = workspace_ent[name];
    if(!ent)return;
    const Element = workspace_cat[ent.id].DOM;
    if(workspaceLast)workspaceLast.classList.add('workspace-hide');
    if(workspaceLastActive)workspaceLastActive.classList.remove('workspace-active');
    Element.classList.add('workspace-active');
    workspaceLast=document.getElementById(workspace_ent[name].id);
    workspaceLastActive=Element;
    workspaceLast.classList.remove('workspace-hide');
    DragElement(ent.DOM);
};

const DynamicConfigCBs = {
    name: (prev,now,e)=>{
        setTimeout(()=>{
            if(QuickAccess.hasOwnProperty(now)){
                e.value=prev;
                return false;
            };
            const elem = GetQuickElement(prev);
            elem.name = now;
            elem.DOM.querySelector('.element-name').textContent="ID: "+now;
            ChangeQuickElement(prev,now);
            e.parentNode.parentNode.parentNode.querySelector('.category-element-header>span').textContent = now;
            workspace_ent[now]=workspace_ent[prev];
            delete(workspace_ent[prev]);
            post('update_entity_name', {name: prev, new: now, scene_id: elem.scene_id});
        }, Math.floor(Math.random()*50))
    },
    coords: (prev,value,e)=>{
        let [x,y,z] = value.split(',').map(parseFloat);
        if(x===undefined||y===undefined||z===undefined){
            e.value = prev;
            return;
        };
        post('update_entity_coords', {name: e.querySelector('.category-element-header>span')?.textContent||e.parentNode.parentNode.parentNode.querySelector('.category-element-header>span').textContent, coords: {x:x, y:y, z:z}});
    },
    rot: (prev,value,e)=>{
        let [x,y,z] = value.split(',').map(parseFloat);
        if(x===undefined||y===undefined||z===undefined){
            e.value = prev;
            return;
        };
        post('update_entity_rotation', {name: e.querySelector('.category-element-header>span')?.textContent||e.parentNode.parentNode.parentNode.querySelector('.category-element-header>span').textContent, rot: {x:x, y:y, z:z}});
    },
    mission: (value,e)=>{
        post('update_entity_mission', {name: e.querySelector('.category-element-header>span')?.textContent||e.parentNode.parentNode.parentNode.querySelector('.category-element-header>span').textContent, value: value});
    },
    network: (value,e)=>{
        post('update_entity_network', {name: e.querySelector('.category-element-header>span')?.textContent||e.parentNode.parentNode.parentNode.querySelector('.category-element-header>span').textContent, value: value});
    },
    classes: (prev,value,e)=>{
        const inputString = value;
        const regex = /#([^#]+)/g;
        const matches = [];
        let match;
        while ((match = regex.exec(inputString))) {
            matches.push(match[1]);
        };
        if(matches.length>0){
            post('update_entity_classes', {name: e.querySelector('.category-element-header>span')?.textContent||e.parentNode.parentNode.parentNode.querySelector('.category-element-header>span').textContent, value: matches});
        };
    }
};

function SetupDynamicConfigElement(elem) {
    const name = elem.querySelector('input[name="name"]');
    const coords = elem.querySelector('input[name="coords"]');
    const rot = elem.querySelector('input[name="rot"]');
    const mission = elem.querySelector('input[name="mission"]');
    const network = elem.querySelector('input[name="network"]');
    const classes = elem.querySelector('input[name="classes"]');
    const iterable = [name,coords,rot,mission,network,classes];
    iterable.forEach(r=>{
        if(r.type==='text'){
            r.addEventListener('keydown', (e)=>{
                const prev = e.target.value;
                setTimeout(()=>{
                    if(prev===e.target.value)return;
                    if(DynamicConfigCBs[e.target.name])DynamicConfigCBs[e.target.name](prev,e.target.value,r);
                },1);
            });
        } else if(r.type==='checkbox'){
            r.addEventListener('click', (e)=>{
                if(DynamicConfigCBs[e.target.name])DynamicConfigCBs[e.target.name](e.target.checked,r)
            });
        };
    });
};

function WorkspaceUpdateData(data) {
    const entity = data.entity;
    const element = workspace_ent[entity].DOM
    Object.keys(data).forEach((e)=>{
        if(!DynamicConfigCBs[e])return;
        if(e=='mission'||e=='network'){
            DynamicConfigCBs[e](data[e],element);
            element.querySelector(`input[name="${e}"]`).checked = data[e];
        } else {
            const r = element.querySelector(`input[name="${e}"]`);
            if(DynamicConfigCBs[e](r.value,data[e],element)===false)return;
            r.value = data[e];
        };
    });
};

document.addEventListener('removed-entity', (e)=>{
    const id = e.detail.name;
    if(!workspace_ent.hasOwnProperty(id))return;
    const ent = workspace_ent[id];
    const children = workspace_cat[ent.id].children;
    for(let i=0;i<children.length;i++){
        if(children[i]===ent){
            ent.DOM.remove();
            children.splice(i,1);
            break;
        };
    };
    delete(QuickAccess[id]);
    delete(workspace_ent[id]);
});

document.addEventListener('scene-created', (e)=>{
    const id = e.detail.id;
    AddWorkspaceHeaderElement(id);
});

document.addEventListener('scene-deleted', (e)=>{
    const id = e.detail.id;
    workspaceDrag.RemoveFromList(workspace_cat[id].DOM);
    workspace_cat[id].children.forEach(child=>{
        child.DOM.remove();
        delete(workspace_ent[child.name]);
    });
    workspace_cat[id].DOM.remove();
    workspace_cat[id].container.remove();
    delete(workspace_cat[id]);
});

document.addEventListener('entity-added', (e)=>{
    const id = e.detail.id;
    const name = e.detail.name;
    AddWorkspaceCategoryElement(name,id);
});

document.addEventListener('entity-moved', (e)=>{
    const [from,to,id] = [e.detail.from,e.detail.to,e.detail.entity];
    ChangeWorkspaceSingleElementCategory(from,to,workspace_ent[id],id);
});

document.addEventListener('entity-name-changed', (e)=>{
    const [oldName,newName] = [e.detail.old,e.detail.new];
    if(!workspace_ent.hasOwnProperty(oldName))return;
    const ent = workspace_ent[oldName];
    ent.name = newName;
    ent.DOM.querySelector('.category-element-header>span').textContent = newName;
    ent.DOM.querySelector('.category-element-main>*>input[name="name"]').value = newName;
});