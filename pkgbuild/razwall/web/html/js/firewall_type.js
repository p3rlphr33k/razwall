function toggleTypes(direction) {
    
    var selected = document.getElementsByName(direction+'_type')[0];
    for (var i = 0; i < selected.options.length; i++) {
        var title = document.getElementById(direction+'_'+selected.options[i].value+'_t');
        if (title != null) {
            title.style.display = 'none';
        }
        var value = document.getElementById(direction+'_'+selected.options[i].value+'_v');
        if (value != null) {
            value.style.display = 'none';
        }
    }

    var enabletitle = document.getElementById(direction+'_'+selected.value+'_t')
    if (enabletitle != null) {
        enabletitle.style.display = 'block';
    }
    var enablevalue = document.getElementById(direction+'_'+selected.value+'_v')
    if (enablevalue != null) {
        enablevalue.style.display = 'block';
    }
}
