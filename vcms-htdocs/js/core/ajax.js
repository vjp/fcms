function defcallbackjq(json){
	//$$('input[type="button"]').each(function(item) { item.enable();	});
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


function lexecutejq(func,objid,data,callback,url) {
	var def_url=(typeof(ajax_url) != "undefined")?ajax_url:'/cgi-bin/ajax-json.pl';
	
	$.ajax({
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
	
	/*new Ajax.Request(url || def_url, {
		method:'post',	
		parameters: {
			lfunc: func,
			objid:objid,
			data: Object.toJSON(data)
		},
		onSuccess: function(transport) {
			var json = transport.responseText.evalJSON();
			if (callback) {
				callback(json)
			} else {
				defcallback(json)
			}	
		}
	});*/
}