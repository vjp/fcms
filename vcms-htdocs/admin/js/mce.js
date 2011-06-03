function insertimage (text,alttext){ 
        if (alttext) {
        	tinyMCE.execCommand('mceInsertContent', false, ' <img border="0" src="'+text+'" onmouseover="this.src=\''+alttext+'\'" onmouseout="this.src=\''+text+'\'"/> ');
        } else { 
        	tinyMCE.execCommand('mceInsertContent', false, ' <img border="0" src="'+text+'"/> ');
        }	 
        tinyMCE.execCommand('mceInsertContent', false, ''); 
    }


function insertbwimage (text){ 
    tinyMCE.execCommand('mceInsertContent', false, ' <img src="'+text+'"  border="0" onload="javascript:prepareMouseOverImage(this, this.src);"/> '); 
    tinyMCE.execCommand('mceInsertContent', false, ''); 
}


    function insertlink (src,name){ 
        tinyMCE.execCommand('mceInsertContent', false, ' <a href="'+src+'"/>'+name+'</a> '); 
        tinyMCE.execCommand('mceInsertContent', false, ''); 
    } 
    function insertvideo (id,pic){ 
        tinyMCE.execCommand('mceInsertContent', false, '<div style="width:320px; height:240px; align:center;  background-image:url('+pic+'); background-repeat:no-repeat; background-position:center; " id="'+id+'"></div>');
        tinyMCE.execCommand('mceInsertContent', false, '');
    } 

    function toggleEditor(id) {
        var elm = document.getElementById(id);

        if (tinyMCE.getInstanceById(id) == null)
            tinyMCE.execCommand('mceAddControl', false, id);
        else
            tinyMCE.execCommand('mceRemoveControl', false, id);
    }