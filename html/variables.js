//Some innerHTMLs or Objects for the rest of script

const InnerForm = `
    <div class="fa-solid fa-x" onclick="RemoveSceneDropdownForm()"></div>
    <div class="scene-form-container">
        <div onclick="SelectedFormOption('change')">Change Name</div>
        <div onclick="SelectedFormOption('delete')">Delete</div>
    </div>
`;

const InnerChildForm = `
    <div class="fa-solid fa-x" onclick="RemoveSceneDropdownForm()"></div>
    <div class="scene-form-container">
        <div onclick="SelectedFormOption('select')">Select</div>
        <div onclick="SelectedFormOption('focus')">Focus In Workspace</div>
        <div onclick="SelectedFormOption('go_to')">Go To</div>
        <div onclick="SelectedFormOption('delete')">Delete</div>
    </div>
`;

const InnerSceneForm = `
    <div class="fa-solid fa-x" onclick="RemoveSceneDropdownForm()"></div>
    <div class="scene-form-container">
        <div onclick="SelectedFormOption('create')">Create Scene</div>
    </div>
`;

const InnerWorkspaceForm = `
    <div class="fa-solid fa-x" onclick="RemoveSceneDropdownForm()"></div>
    <div class="scene-form-container">
        <div onclick="SelectedFormOption('add')">Add Entity</div>
    </div>
`;

const InnerWorkspaceHeaderForm = `
    <div class="fa-solid fa-x" onclick="RemoveSceneDropdownForm()"></div>
    <div class="scene-form-container">
        <div onclick="SelectedFormOption('add')">Create Scene</div>
    </div>
`;

const InnerWorkspaceHeaderElementForm = `
    <div class="fa-solid fa-x" onclick="RemoveSceneDropdownForm()"></div>
    <div class="scene-form-container">
        <div onclick="SelectedFormOption('change')">Change Name</div>
        <div onclick="SelectedFormOption('send')">Send All To Scene</div>
        <div onclick="SelectedFormOption('delete')">Delete</div>
    </div>
`;

const InnerWorkspaceHeaderElementFormMain = `
    <div class="fa-solid fa-x" onclick="RemoveSceneDropdownForm()"></div>
    <div class="scene-form-container">
        <div onclick="SelectedFormOption('send')">Send All To Scene</div>
    </div>
`;

const InnerScene = `
    <span class="wrapper-title">
        <span>Scene: $ID</span>
        <div class="wrapper-hide-show fa-solid fa-arrow-down" onclick="ChangeSceneDropdownState(this)"></div>
    </span>
    <div class="wrapper-content"></div>
`;

const InnerSceneElement = `
    <div class="element-icon fa-solid fa-$TYPE"></div>
    <div class="element-name">ID: $ID</div>
`;

const Options = {
    [1]: [
        {name: 'model', default: 'a_m_m_mexlabor_01', type: 'text'},
        {name: 'network', default: false, type: 'checkbox'},
        {name: 'bScript', default: false, type: 'checkbox'}
    ],
    [2]: [
        {name: 'model', default: 'blista', type: 'text'},
        {name: 'network', default: false, type: 'checkbox'},
        {name: 'mission', default: false, type: 'checkbox'}
    ],
    [3]: [
        {name: 'model', default: 'prop_weed_block_01', type: 'text'},
        {name: 'network', default: false, type: 'checkbox'},
        {name: 'mission', default: false, type: 'checkbox'},
        {name: 'door', default: false, type: 'checkbox'}
    ]
};

const OptionsInner = {
    text: `
        <div><span class="form-name">$NAME</span>&nbsp<input value="$VALUE" type="text"></div>
    `,
    checkbox: `
        <div><span class="form-name">$NAME</span>&nbsp<input $VALUE type="checkbox"></div>
    `,
    list: `
        <div><span class="form-name">$NAME</span>&nbsp<select id="$ID">$VALUE</select></div>
    `
};

const CategoryElementOptions = `
    <div class="fa-solid fa-x" onclick="RemoveSceneDropdownForm()"></div>
    <div class="scene-form-container">
        <div onclick="SelectedFormOption('change')">Change Category</div>
        <div onclick="SelectedFormOption('delete')">Delete</div>
    </div>
`;

const CategoryElementHTML = `
    <div class="category-element-header">
        <span>$NAME</span>
        <div class="wrapper-hide-show fa-solid fa-arrow-down" style="animation: rotate-to-hide 0s forwards;" onclick="ChangeSceneDropdownState(this)"></div>    
    </div>
    <div class="category-element-main"></div>
`;

const InnerCategoryElementHTML = `
    <div><span>name: </span><input name="name" type="text" value="$NAME"></div>
    <div><span>coords: </span><input name="coords" type="text" value="0.0,0.0,0.0"></div>
    <div><span>rot: </span><input name="rot" type="text" value="0.0,0.0,0.0"></div>
    <div><span>mission: </span><input name="mission" type="checkbox"></div>
    <div><span>network: </span><input name="network" type="checkbox"></div>
`;

const InnerNotification = `
    <div class="notif-title">$NAME</div>
    <div class="notif-desc">$DESC</div>
    <div class="notif-time" style="background-color:$COLOR"></div>
`;

const InnerSelectForm = `
    <div class="fa-solid fa-x" onclick="RemoveSceneDropdownForm()"></div>
    <div class="scene-form-container">
        <div onclick="SelectedFormOption('stop2')">(All)Stop Selecting</div>
        <div onclick="SelectedFormOption('change2')">(All)Change Scene</div>
        <div onclick="SelectedFormOption('send2')">(All)Create and Change Scene</div>
        <div onclick="SelectedFormOption('delete2')">(All)Delete</div>
    </div>
`;

const InnerInformation = `
    <div class="info-title">$TITLE</div>
    <div class="info-main"></div>
`;

const InformationTypes = {
    'text': 'info-text',
    'slider': 'info-slider',
    'var': 'info-var'
};

const CustomMenu = `
    <div class="header cm-gradient"></div>
    <div class="main">
        <nav class="nav"></nav>
        <div class="container"></div>
    </div>
    <div class="cm-resize"></div>
`;

const InnerCustomMenuNav = `
    <a href="#">$TEXT</a><div class="nav-underline"></div><div class="nav-background"></div>
`;

const InnerCustomMenuContainer = `
    <div class="first-block"></div>
    <div class="second-block"></div>
`;

const InnerCustomMenu2 = `
    <div class="menu-title cm-gradient-color">$TEXT</div>
    <div class="cm-gradient"></div>
    <div class="menu-inner"></div>
`;

const CustomMenuTypes = {
    checkbox: `<div class="cm-menu-element"><div class="cm-menu-checkbox" onclick="CMenuCheckbox(this,'$ID')"></div><span>$TEXT</span></div>`,
    list: `<div class=cm-menu-element><span>$TEXT</span><select title="$ID" class="cm-menu-list" onclick="CMenuListClicked(this)">$OPTIONS</select></div>`,
    slider: `<div class=cm-menu-element><span>$TEXT</span><div class="cm-menu-slider"><div class="cm-menu-innerslider cm-gradient"></div></div></div>`,
    button: `<div class="cm-menu-element"><div class="cm-menu-button" onclick="CMenuButtonClicked(this,'$ID')">$TEXT</div></div>`,
    input: `<div class="cm-menu-element"><span>$TEXT</span><input class="cm-menu-input" type="$TYPE" value="$VALUE" name="$ID"></div>`,
    text: '<div class="cm-menu-element" id="CMTEXT$ID">$TEXT</div>'
};

/*
const CustomMenu = `
    <div class="cm-header cm-gradient"></div>
    <div class="cm-main">
        <div class="cm-main-nav"></div>
        <div class="cm-main-data"></div>
    </div>
    <div class="cm-resize"></div>
`;

const InnerCustomMenuNav = `
    <span>$TEXT</span><div class="cm-nav-underline"></div><div class="cm-nav-menu-background"><div></div></div>
`;

const InnerCustomMenuContainer = `
    <div class="cm-container-fcolumn"></div>
    <div class="cm-container-scolumn"></div>
`;

const InnerCustomMenu2 = `
    <div class="cm-menu-title cm-gradient-color">$TEXT</div>
    <div class="cm-gradient"></div>
    <div class="cm-menu-inner"></div>
`;

const CustomMenuTypes = {
    checkbox: `<div class="cm-menu-element"><div class="cm-menu-checkbox" onclick="CMenuCheckbox(this,'$ID')"></div><span>$TEXT</span></div>`,
    list: `<div class=cm-menu-element><span>$TEXT</span><select title="$ID" class="cm-menu-list" onclick="CMenuListClicked(this)">$OPTIONS</select></div>`,
    slider: `<div class=cm-menu-element><span>$TEXT</span><div class="cm-menu-slider"><div class="cm-menu-innerslider cm-gradient"></div></div></div>`,
    button: `<div class="cm-menu-element"><div class="cm-menu-button" onclick="CMenuButtonClicked(this,'$ID')">$TEXT</div></div>`,
    input: `<div class="cm-menu-element"><span>$TEXT</span><input class="cm-menu-input" type="$TYPE" value="$VALUE" name="$ID"></div>`
};*/