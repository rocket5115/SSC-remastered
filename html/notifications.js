let notifications;

function EnsureNotifications() {
    if(notifications)return;
    notifications = document.querySelector('.notifications');
    /*AddNotification({
        title: 'Information',
        message: 'SSC Notifications successfully loaded',
        time: 5000,
        color: 'yellow'
    })*/
};

function AddNotification(options={}) {
    if(!notifications)return;
    const name = options.title||'N/a';
    const time = options.time||5000;
    const description = options.message||'-';
    const color = options.color||'blue';
    const element = document.createElement('div');
    element.classList.add('notifications-element');
    element.innerHTML = InnerNotification.replace('$NAME',name).replace('$DESC',description).replace('$COLOR',color);
    element.style.animation = `notification-element-show 500ms ease-in-out forwards`;
    element.querySelector('.notif-time').style.animation = `notification-element-line ${time}ms ease-in-out forwards`;
    setTimeout(()=>{
        element.style.animation = 'notification-element-hide 500ms ease-in-out forwards';
        setTimeout(() => {
            element.remove();
        }, 500);
    }, time);
    notifications.append(element);
};

function SendError(msg,options={}) {
    options.title = 'error';
    options.message = msg;
    options.color = 'red';
    options.time = 4000;
    AddNotification(options);
};

window.addEventListener('mousemove', function(e) {
    const [x,y] = [(e.clientX / window.innerWidth).toFixed(2),(e.clientY / window.innerHeight).toFixed(2)]
    //console.log(`Mouse position percentage; X: ${x}% Y: ${y}%`);
});