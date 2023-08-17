let menu = null;
let [n,b] = [null,null];
let lastContainer = null;
let lastNav = null;
let menuCbs = {};
let lastSelectedList = null;
let lastMinDimensions = null;
let lastElementsDisplay = null;

function CreateMenu(options) {
    menu = document.createElement('div');
    menu.classList.add('custom-menu');
    menu.innerHTML = CustomMenu;
    menuCbs = options.cbs;
    n = menu.querySelector('.nav');
    b = menu.querySelector('.container');
    menu.querySelector('.header').addEventListener('mousedown', (e)=>{
        DragElement(e.target, true);
    });
    menu.querySelector('.cm-resize').addEventListener('mousedown', (e)=>{
        ResizeMenu(e.target.parentNode, {x:500,y:200});
    });
    $('body').append(menu);
    let bcr = menu.getBoundingClientRect();
    lastMinDimensions = {x:bcr.x, y:bcr.y, w:bcr.width, h:bcr.height};
    lastElementsDisplay={};
    MenuSetOptions(options);
};

function SetCMenuDisplay(bool=false) {
    if(!menu)return;
    if(bool){
        menu.style.display = 'grid';
    } else {
        menu.style.display = 'none';
    };
};

function RemoveMenu() {
    if(menu)menu.remove();
};

function MenuSetOptions(options={}) {
    const nav = options.nav;
    const menus = options.menu;
    const defs = options.defaults;
    const navs = {};
    nav.forEach(name=>{
        const div = document.createElement('div');
        div.classList.add('nav-menu');
        div.innerHTML = InnerCustomMenuNav.replace('$TEXT',name);
        div.onclick = (e)=>{
            CMenuFocusOn(name,e.target.parentNode.querySelector('.nav-background'));
        };
        n.append(div);
        const container = document.createElement('div');
        container.classList.add('container-wrapper');
        container.innerHTML = InnerCustomMenuContainer;
        container.id = 'cm-'+name;
        b.append(container);
        navs[name]=container;
    });
    const close = document.createElement('div');
    close.classList.add('nav-menu');
    close.innerHTML = InnerCustomMenuNav.replace('$TEXT','<span style="color:red">close</span>');
    close.onclick = ()=>{
        SetCMenuDisplay(false);
    };
    n.append(close);
    let nums = {};
    menus.forEach((v,k)=>{
        if(!navs[v.nav])return;
        nums[v.nav]=nums[v.nav]!==undefined?nums[v.nav]:-1;
        nums[v.nav]++;
        let selector = nums[v.nav]%2===0?'.first-block':'.second-block';
        let menu = document.createElement('div');
        menu.classList.add('container-menu');
        menu.innerHTML = InnerCustomMenu2.replace("$TEXT",v.title||"");
        selector = navs[v.nav].querySelector(selector);
        if(v.display!==undefined&&typeof v.display==='boolean'&&!v.display){
            menu.style.display = 'none';
        } else if(typeof v.display==='function'){
            if(v.display(menu)){
                menu.style.display = 'block';
            } else {
                menu.style.display = 'none';
            };
            lastElementsDisplay["CMenu"+(v.id||v.title)]={
                DOM: menu,
                func: v.display
            };
        }
        PrepareCMenu(menu.querySelector('.menu-inner'), v.options, defs);
        selector.append(menu);
    });
};

function PrepareCMenu(DOM, options=[], defs={}) {
    options.forEach(e=>{
        if(e.id&&defs.hasOwnProperty(e.id))e.default=defs[e.id];
        let div = document.createElement('div');
        div.innerHTML = CustomMenuTypes[e.type]?.replace('$TEXT',e.title).replace('$ID',e.id||'');
        if(e.type==='list'){
            let res = "";
            e.options.forEach(o=>{
                res=res+`<option value="${o.id||o.title}">${o.title}</option>`
            });
            div.innerHTML=div.innerHTML.replace('$OPTIONS',res);
        } else if(e.type==='slider'){
            const innerdiv = div.querySelector('.cm-menu-innerslider');
            let lastpercent=0;
            if(e.default){
                lastpercent=e.default;
                innerdiv.style.width=lastpercent+'%';
            };
            div.addEventListener('mousedown', ()=>{
                const bcr = div.getBoundingClientRect();
                let percentX = Math.floor(101-(-(x-(bcr.left+bcr.width))));
                if(percentX<0)percentX=0;
                if(percentX>100)percentX=100;
                if(lastpercent!=percentX){
                    CMenuSliderMoved(e.id||e.title,percentX);
                    lastpercent=percentX;
                };
                innerdiv.style.width = percentX+'%';
                MoveListen((x,y)=>{
                    const bcr = div.getBoundingClientRect();
                    let percentX = Math.floor(101-(-(x-(bcr.left+bcr.width))));
                    if(percentX<0)percentX=0;
                    if(percentX>100)percentX=100;
                    if(lastpercent!=percentX){
                        CMenuSliderMoved(e.id||e.title,percentX);
                        lastpercent=percentX;
                    };
                    innerdiv.style.width = percentX+'%';
                });
            });
        } else if(e.type==='checkbox'){
            if(e.default){
                div.querySelector('.cm-menu-checkbox').classList.add('cm-checked');
            };
        } else if(e.type==='input'){
            div.innerHTML = div.innerHTML.replace('$TYPE', e._type||'text').replace('$VALUE', e.default||'');
            div.addEventListener('input', (r)=>{
                CMenuInputEntered(r.target.name,r.target.value);
            });
            if(e.id){
                div.querySelector('.cm-menu-element>.cm-menu-input').id = 'CMI'+e.id;
            }
        };
        DOM.append(div)
        if(e.id&&e.default&&menuCbs.hasOwnProperty(e.id)){
            menuCbs[e.id](e.default,e.id);
        };
        if(e.display!==undefined&&typeof e.display==='boolean'&&!e.display){
            div.style.display = 'none';
        } else if(typeof e.display==='function'){
            if(e.display(div)){
                div.style.display = 'block';
            } else {
                div.style.display = 'none';
            };
            lastElementsDisplay[e.id||e.title]={
                DOM: div,
                func: e.display
            };
        }
    });
};

function CMenuListClicked(e) {
    if(!menu.hasOwnProperty(e.title))return;
    if(lastSelectedList===e.options[e.selectedIndex].value)return;
    lastSelectedList = e.options[e.selectedIndex].value;
    menu[e.title](lastSelectedList);
};

function CMenuFocusOn(name,e) {
    if(lastContainer){
        lastContainer.classList.remove('cm-active');
        lastNav.classList.remove('nav-active');
    };
    if(lastContainer&&lastContainer.id==='cm-'+name){
        lastContainer=null;
        lastNav=null;
        return;
    };
    lastContainer = document.getElementById('cm-'+name);
    lastNav = e;
    if(!lastContainer)return;
    lastContainer.classList.add('cm-active');
    lastNav.classList.add('nav-active');
};

function CMenuChecked(id,value) {
    if(id==='')return;
    if(!menuCbs.hasOwnProperty(id))return;
    menuCbs[id](value,id);
};

function CMenuCheckbox(e,id) {
    let checked = e.classList.contains('cm-checked');
    checked=!checked;
    if(checked){
        e.classList.add('cm-checked');
        CMenuChecked(id,true);
    } else {
        e.classList.remove('cm-checked');
        CMenuChecked(id,false);
    };
};

function CMenuSliderMoved(id,value) {
    if(id==='')return;
    if(!menuCbs.hasOwnProperty(id))return;
    menuCbs[id](value,id);
};

function CMenuButtonClicked(_,id) {
    if(id==='')return;
    if(!menuCbs.hasOwnProperty(id))return;
    menuCbs[id](id);
};

function CMenuInputEntered(id,value) {
    if(id==='')return;
    if(!menuCbs.hasOwnProperty(id))return;
    menuCbs[id](value,id);
};

function CMenuTriggerDisplayFuncs() {
    Object.keys(lastElementsDisplay).forEach(k=>{
        let dom = lastElementsDisplay[k].DOM;
        if(lastElementsDisplay[k].func(dom)){
            dom.style.display = 'block';
        } else {
            dom.style.display = 'none';
        };
    });
};

function CMenuSetSelectOptions(select, e, cb) {
    if(e.length==0){
        select.innerHTML = '<option value="none">None</option>';
    } else {
        let retval = "";
        e.forEach(elem=>{
            retval=retval+`<option value="${elem}">${elem}</option>`
            if(cb)cb(elem);
        });
        select.innerHTML = retval;
    };
    CMenuTriggerDisplayFuncs();
};

let loaded = undefined;
const Templates = [];
const Sessions = [];
const Files = [];
const AttachedFiles = [];

document.addEventListener('loaded-session', (e)=>{
    loaded = e.detail.id;
    menuCbs['refresh_a_files']();
    CMenuTriggerDisplayFuncs();
});

document.addEventListener('unloaded-session', (e)=>{
    loaded = undefined;
    CMenuTriggerDisplayFuncs();
});

$(document).ready(()=>{
    CreateMenu({
        defaults: {opacity: 100},
        nav: ['editor','settings','menu'],
        menu: [
            {
                nav: 'editor',
                title: 'session',
                options: [
                    {
                        type: 'text',
                        title: ``,
                        id: 'loaded',
                        display: (e)=>{
                            e.querySelector('.cm-menu-element').innerHTML = `Loaded: <span style="color:${loaded!==undefined?'green':'red'}">${loaded||'NO'}</span>`;
                            return true;
                        }
                    },
                    {
                        type: 'list',
                        title: 'Sessions',
                        id: 'session',
                        display: ()=>{
                            return loaded===undefined;
                        },
                        options: [
                            {
                                title: 'None',
                                id: 'none'
                            }
                        ]
                    },
                    {
                        type: 'button',
                        title: 'Load Session',
                        id: 'load_session',
                        display: ()=>{
                            return loaded===undefined;
                        }
                    },
                    {
                        type: 'button',
                        title: 'Refresh Sessions',
                        id: 'refresh_session',
                        display: ()=>{
                            return loaded===undefined;
                        }
                    },
                    {
                        type: 'button',
                        title: 'Remove Session',
                        id: 'remove_session',
                        display: ()=>{
                            return loaded===undefined;
                        }
                    },
                    {
                        type: 'input',
                        title: 'S_Name',
                        id: 'sessionName',
                        display: ()=>{
                            return loaded===undefined;
                        }
                    },
                    {
                        type: 'button',
                        title: 'Create Session',
                        id: 'create_session',
                        display: ()=>{
                            return loaded===undefined;
                        }
                    },
                    {
                        type: 'button',
                        title: 'Save Session',
                        id: 'save_session',
                        display: ()=>{
                            return loaded!==undefined;
                        }
                    },
                    {
                        type: 'button',
                        title: 'Unload Session',
                        id: 'unload_session',
                        display: ()=>{
                            return loaded!==undefined;
                        }
                    },
                ]
            },
            {
                nav: 'editor',
                title: 'template',
                display: ()=>{
                    return loaded!==undefined;
                },
                options: [
                    {
                        type: 'list',
                        title: 'Templates',
                        id: 'template',
                        options: [
                            {
                                title: 'None',
                                id: 'none'
                            }
                        ]
                    },
                    {
                        type: 'button',
                        title: 'Load Template',
                        id: 'load_template',
                        display: ()=>{
                            return Templates.length>0;
                        }
                    },
                    {
                        type: 'button',
                        title: 'Refresh Templates',
                        id: 'refresh_templates',
                    },
                    {
                        type: 'input',
                        title: 'T_Name',
                        id: 'templateName'
                    },
                    {
                        type: 'button',
                        title: 'Create Template',
                        id: 'create_template'
                    }
                ]
            },
            {
                nav: 'editor',
                title: 'metadata',
                display: ()=>{
                    return loaded!==undefined;
                },
                options: [
                    {
                        type: 'list',
                        title: 'Available Files',
                        id: 'files',
                        options: [
                            {
                                title: 'None',
                                id: 'none'
                            }
                        ],
                    },
                    {
                        type: 'button',
                        title: 'Attach File',
                        id: 'attach_file',
                        display: ()=>{
                            return Files.length>0;
                        }
                    },
                    {
                        type: 'button',
                        title: 'Refresh Files',
                        id: 'refresh_files'
                    },
                    {
                        type: 'list',
                        title: 'Attached Files',
                        id: 'a_files',
                        options: [
                            {
                                title: 'None',
                                id: 'none'
                            }
                        ],
                    },
                    {
                        type: 'button',
                        title: 'Detach File',
                        id: 'detach_file',
                        display: ()=>{
                            return AttachedFiles.length>0;
                        }
                    },
                    {
                        type: 'button',
                        title: 'Refresh A_Files',
                        id: 'refresh_a_files'
                    }
                ]
            },
            {
                nav: 'settings',
                title: 'All',
                options: [
                    {
                        type: 'input',
                        title: 'Font Size',
                        id: 'fontSize',
                        _type: 'number',
                        default: '16'
                    },
                    {
                        type: 'button',
                        title: 'Reset Font Size',
                        id: 'reset-font'
                    },
                    {
                        type: 'slider',
                        title: 'Opacity',
                        id: 'opacity',
                        default: 100
                    }
                ]
            },
            {
                nav: 'editor',
                title: 'misc',
                display: ()=>{
                    return loaded!==undefined;
                },
                options: [
                    {
                        type: 'input',
                        title: 'Static Id',
                        id: 'staticId'
                    },
                    {
                        type: 'button',
                        title: 'Create Static Map',
                        id: 'create_static_map'
                    }
                ]
            },
            {
                nav: 'menu',
                title: 'Menu',
                options: [,
                    {
                        type: 'input',
                        title: 'Font Size Multiplier',
                        id: 'MenufontSize',
                        _type: 'number',
                        default: '0'
                    },
                    {
                        type: 'button',
                        title: 'Reset Font Size',
                        id: 'Menureset-font'
                    },
                    {
                        type: 'button',
                        title: 'Reset Resize',
                        id: 'reset-resize'
                    },
                    {
                        type: 'button',
                        title: 'Reset Position',
                        id: 'reset-position'
                    }
                ]
            }
        ],
        cbs: {
            //Editor Nav
            //session menu
            'save_session': ()=>{
                post('save_session',{});
            },
            'unload_session': ()=>{
                post('unload_session',{});
                loaded = undefined;
                CMenuTriggerDisplayFuncs();
            },
            'load_session': ()=>{
                const select = document.querySelector('select[title="session"]');
                const value = select.options[select.selectedIndex].value;
                if(value==='none')return;
                post('load_session', {id: value});
            },
            'refresh_session': ()=>{
                post('get_sessions', {}).then((e)=>{
                    const select = document.querySelector('select[title="session"]');
                    Sessions.length = 0;
                    CMenuSetSelectOptions(select, e, (elem)=>{Sessions.push(elem);});
                });
            },
            'remove_session': ()=>{
                const select = document.querySelector('select[title="session"]');
                const value = select.options[select.selectedIndex].value;
                if(value==='none')return;
                post('remove_session', {id: value});
                menuCbs['refresh_session']();
            },
            'create_session': ()=>{
                const name = document.getElementById('CMIsessionName').value;
                if(name==='')return;
                post('create_session', {name: name});
            },
            //template menu
            'refresh_templates': ()=>{
                post('get_templates', {}).then((e)=>{
                    const select = document.querySelector('select[title="template"]');
                    Templates.length = 0;
                    CMenuSetSelectOptions(select, e, (elem)=>{Templates.push(elem);});
                });
            },
            'load_template': ()=>{
                const select = document.querySelector('select[title="template"]');
                const value = select.options[select.selectedIndex].value;
                if(value==='none')return;
                post('load_template', {id: value});
            },
            'create_template': ()=>{
                const name = document.getElementById('CMItemplateName').value;
                if(name==='')return;
                post('create_template', {name: name});
            },
            //metadata menu
            'refresh_files': ()=>{
                post('refresh_a_files', {}).then((e)=>{
                    const select = document.querySelector('select[title="a_files"]');
                    AttachedFiles.length=0;
                    CMenuSetSelectOptions(select, e, (elem)=>{AttachedFiles.push(elem);});
                });
                setTimeout(()=>{
                    post('refresh_files', {}).then((e)=>{
                        const select = document.querySelector('select[title="files"]');
                        Files.length=0;
                        for(let i=AttachedFiles.length;i>=0;i--){
                            if(e.includes(AttachedFiles[i])){
                                e.splice(i,1);
                            };
                        };
                        CMenuSetSelectOptions(select, e, (elem)=>{Files.push(elem);});
                    });
                },0);
            },
            'refresh_a_files': ()=>{
                post('refresh_a_files', {}).then((e)=>{
                    const select = document.querySelector('select[title="a_files"]');
                    AttachedFiles.length=0;
                    CMenuSetSelectOptions(select, e, (elem)=>{AttachedFiles.push(elem);});
                });
                setTimeout(()=>{
                    post('refresh_files', {}).then((e)=>{
                        const select = document.querySelector('select[title="files"]');
                        Files.length=0;
                        for(let i=AttachedFiles.length;i>=0;i--){
                            if(e.includes(AttachedFiles[i])){
                                e.splice(i,1);
                            };
                        };
                        CMenuSetSelectOptions(select, e, (elem)=>{Files.push(elem);});
                    });
                },0);
            },
            'attach_file': ()=>{
                const select = document.querySelector('select[title="files"]');
                const value = select.options[select.selectedIndex].value;
                if(value==='none')return;
                post('attach_file', {name: value});
                menuCbs['refresh_a_files']();
            },
            'detach_file': ()=>{
                const select = document.querySelector('select[title="a_files"]');
                const value = select.options[select.selectedIndex].value;
                if(value==='none')return;
                post('detach_file', {name: value});
                menuCbs['refresh_files']();
            },
            //Misc menu
            'create_static_map': ()=>{
                const name = document.getElementById('CMIstaticId').value;
                if(name==='')return;
                post('create_static_map', {name: name});
            },
            //Settings Nav
            'opacity': (value)=>{
                value = (value/100)+0.1;
                if(value>1.0)value=1.0;
                document.documentElement.style.setProperty('--body-opacity', value);
            },
            'fontSize': (value,id)=>{
                if(value<12){
                    value=12;
                    document.getElementById('CMI'+id).value=value;
                }
                document.documentElement.style.setProperty('--font-default', value+'px');
            },
            'reset-font': ()=>{
                document.getElementById('CMIfontSize').value = '16';
                document.documentElement.style.setProperty('--font-default', '16px');
            },
            //Menu Nav
            'reset-resize': ()=>{
                menu.style.width = lastMinDimensions.w+'px';
                menu.style.height = lastMinDimensions.h+'px';
            },
            'reset-position': ()=>{
                menu.style.transform = `translate(0px,0px)`;
            },
            'MenufontSize': (value)=>{
                document.documentElement.style.setProperty('--cm-font-multiplier', value+'px');
            },
            'Menureset-font': ()=>{
                document.getElementById('CMIMenufontSize').value = '0';
                document.documentElement.style.setProperty('--cm-font-multiplier', '0px');
            },
        }
    });
    setTimeout(()=>{
        menuCbs['refresh_session']();
        menuCbs['refresh_templates']();
        menuCbs['refresh_files']();
        menuCbs['refresh_a_files']();
    },100);
    SetCMenuDisplay(false);
});