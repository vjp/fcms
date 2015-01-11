function defcallbackjq(json){
	jQuery('input[type="button"]').prop('disabled', false);
    if (json.status) {
        alert(json.message || lbSuccess);
        var r=json.redir || json.back;
        if (r=='silent') return 1;
        if (r) {
        	location.href=r;
        } else {
        	location.reload();
        }	
    } else {
        alert(json.message);
    }    
}   

function executejq(func,data,callback,url) {
	var def_url=(typeof(ajax_url) != "undefined")?ajax_url:'/cgi-bin/ajax-json.pl';
	
	jQuery.ajax({
		  type: "POST",
		  url: url || def_url,
	      dataType: "json",
	      data: ({
				func: func,
				data:  JSON.stringify(data)
	      }),
	      success: function(json) {
	    	  if (callback) {
	    		  callback(json)
	    	  } else {
	    		  defcallbackjq(json)
	    	  }	
		  } 
	});	
}

function lexecutejq(func,objid,data,callback,url) {
	var def_url=(typeof(ajax_url) != "undefined")?ajax_url:'/cgi-bin/ajax-json.pl';
	
	jQuery.ajax({
		  type: "POST",
		  url: url || def_url,
	      data: ({
				lfunc: func,
				objid: objid,
				data:  JSON.stringify(data)
	      }),
	      dataType: "json",
	      success: function(json) {
	    	  if (callback) {
	    		  callback(json)
	    	  } else {
	    		  defcallbackjq(json)
	    	  }	
		  } 
	});

}



function multisetjq (frm,fcallback,back,method,sortid) {
	var dt=jQuery(elm).parents("form").serializeObject();
	/*if (sortid) {
		dt.sortstr=Sortable.serialize(sortid);
	} else if ($('sortableList')) {
		dt.sortstr=Sortable.serialize('sortableList');
	}*/
	dt.back=back;
	executejq(method || 'BASELPARSER',dt,fcallback || defcallbackjq);
}

function multisetsingleobjjq (elm,id,fcallback,back,method) {
	/*var nnattr=$(frm).up('form').select('input[notnull="1"]','select[notnull="1"]');
	for (i=0;i<nnattr.length;i++) {
		inp=nnattr[i];
	    if (!inp.value || inp.value==0) {
	    	alert (lbRequired+' "'+inp.attributes['prmname'].value+'"');
	    	inp.activate();
	    	return false;
	    }
	}
	var dattr=$(frm).up('form').select('input[checkdigit="1"]');
	for (i=0;i<dattr.length;i++) {
		inp=dattr[i];
	    if (inp.value && !inp.value.match(/^[\d+\.\-\,]+$/)) {
	    	alert (lbDigit+' "'+inp.attributes['prmname'].value+'"');
	    	inp.activate();
	    	return false;
	    }
	}*/
	var dt=jQuery(elm).parents("form").serializeObject();
	dt.back=back;
	lexecutejq(method || 'BASELPARSER',id,dt,fcallback || defcallbackjq);
}

