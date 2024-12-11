function switchVisibility(id, sw) {
    el = document.getElementById(id);
    if (sw == 'on') {
        el.style.display = 'block'
    } else {
        el.style.display = 'none'
    }
}
