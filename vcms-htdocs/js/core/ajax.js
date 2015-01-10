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

function executejq(func,data,callback,url) {
	var def_url=(typeof(ajax_url) != "undefined")?ajax_url:'/cgi-bin/ajax-json.pl';
	
	$.ajax({
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

}