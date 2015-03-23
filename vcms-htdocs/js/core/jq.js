function defcallbackjq(json){
	jQuery('input[type="button"]').prop('disabled', false);
    if (json.status) {
        if (json.appenddiv) {
        	jQuery.ajax({
        		url: json.redir,
        		type: "get",
        		dataType: "html",
        		success: function(returnData){
        			jQuery('#'+json.appenddiv).append(returnData);
        		},
        	});
        	return 1;
        }
        if (json.popup) {
        	openBootstrapPopupJq(json.redir,{title:json.popuptitle});
        	return 1;
        }
        alert(json.message || lbSuccess);
        var r=json.redir || json.back;
        if (r=='silent') return 1;
        if (r) {
        	location.href=r;
        } else {
        	if (json.anchor) location.hash=json.anchor;
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

function ajax_call_jq(func,data,callback) {
	var def_url=(typeof(ajax_url) != "undefined")?ajax_url:'/cgi-bin/ajax-json.pl';
	
	jQuery.ajax({
		type: "POST",
		url: def_url,
		data: ({
			func: func, 
			data: JSON.stringify(data)
		}),
		success: function(json) {
			callback(json)
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



function multisetjq (elm,fcallback,back,method,sortid) {
	var dt=jQuery(elm).parents("form").serializeForm();
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
	var dt=jQuery(elm).parents("form").serializeForm();
	dt.back=back;
	lexecutejq(method || 'BASELPARSER',id,dt,fcallback || defcallbackjq);
}




jQuery.fn.serializeForm = function () {
	var o = {};
	var a = this.serializeArray();
	jQuery.each(a, function () {
		if (o[this.name] !== undefined) {
			if (!o[this.name].push) {
				o[this.name] = [o[this.name]];
			}
			o[this.name].push(this.value || '');
	    } else {
	    	o[this.name] = this.value || '';
	    }
	});
	return o;
};




function openBootstrapPopupJq (url,opts) {
	jQuery.ajax({
		url: url,
		type: "get",
		dataType: "html",
		success: function(returnData){
			jQuery("#bsModal").html(returnData);
			jQuery("#myModalLabel").text(opts.title);
			jQuery('#bsModal').modal('show');
		},
	});
}


function BSModalCallbackJq(r) {
	jQuery('#bsModal').modal('hide');
	if (r.resultdiv) {
		jQuery('#'+r.resultdiv).html(r.result);
	} else {
		location.reload();
	}
}

function setSelBSJq(formid,id) {
	lexecutejq('BASELPARSER',id,jQuery('#'+formid).serializeForm(),BSModalCallbackJq);
}


function jsErrHandlerJq(message, url, line)
{
    if (navigator.userAgent.search('Firefox') != -1 && message === 'Error loading script') {
        return true;
    }   
    if (line==0) {
    	return true;
    }    
    if (typeof(errorCnt) != "undefined") {
    	errorCnt++;
    	if (errorCnt>1) return true;
    }
    new jQuery.ajax({
    		url:'/cgi-bin/ajax-json.pl', 
            type:'post',  
  	      	data: ({
  	      		func: 'JSERROR', 
  	      		data: JSON.stringify({message:message,url:url,line:line,ua:navigator.userAgent})
  	      	})
    });
    return true;
}



