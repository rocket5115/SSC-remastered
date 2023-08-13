let info = null;
let main = null;

function SetInformation(data={}) {
    info = info || document.createElement('div');
    info.classList.add('informations');
    $('body').append(info);
    const title = data.title||'title';
    const options = data.options;
    info.innerHTML = InnerInformation.replace('$TITLE', title);
    if(!main){
        info.querySelector('.info-title').addEventListener('mousedown', (e)=>{
            DragElement(e.target, true);
        });
    };
    main = main || info.querySelector('.info-main');
    options.forEach(elem=>{
        const div = document.createElement('div');
        div.classList.add(InformationTypes[elem.type]||'info-text');
        if(elem.type==='slider'){
            div.innerHTML = `
                <div>${elem.title}</div>
                <div>
                    <div class="fa-solid fa-chevron-left" onclick="InfoSliderLeft(this)"></div>
                    <div class="info-slider-data"><div><span class="slider-current">${elem.start}</span>/${elem.stop}</div></div>
                    <div class="fa-solid fa-chevron-right" onclick="InfoSliderRight(this)"></div>
                </div>
            `;
            div.classList.add(elem.title);
        } else if (elem.type==='var') {
            div.innerHTML = `
                <span>${elem.text} <span class="info-${elem.id}"></span><span>
            `;
        } else {
            div.textContent = elem.text;
        };
        main.append(div);
    });
};

function RemoveInformation() {
    info&&info.remove();
    main&&main.remove();
    info=null;
    main=null;
};

function InfoSliderLeft(e) {
    const name = e.parentNode.parentNode.querySelector('div').textContent;
    post('slider_left', {name: name});
    InfoSetSlider(name, 100);
};

function InfoSliderRight(e) {
    const name = e.parentNode.parentNode.querySelector('div').textContent;
    post('slider_right', {name: name});
    InfoSetSlider(name, 2);
};

function InfoSetSlider(name, value) {
    document.querySelector("."+name).querySelector('.slider-current').textContent = value;
};

function InfoSetVars(ids) {
    Object.keys(ids).forEach(e=>{
        document.querySelector('.info-'+e).textContent = ids[e];
    });
};