//$Id: ajax.js,v 1.2 2010-05-04 20:26:32 vano Exp $


function alertreload_callback(json){
                    if (json.status) {
                        alert(json.status); 
                        window.location.href=window.location.href.sub(/\#$/,'');
                    } else {
                        alert(json.message);
                    }    
            }   
    
           function deleteobject (parseid,id,parseprm,deleteid) {
                var dt={
                    parseid: parseid,
                    id: id,
                    parseprm: parseprm,                 
                    deleteid: deleteid  
                };
                ajax_call('deleteobject', dt, alertreload_callback);
            }    


            function addobject (up,link,linkval,name,upobj) {
                var dt={
                    up: up,
                    link: link,
                    linkval: linkval,
                    upobj: upobj
                };
                ajax_call('addobject', dt, alertreload_callback);
            }
            
            function exec (id,method) {
                var dt={
                    id: id,
                    method: method,
                };
                ajax_call('execute', dt, alertreload_callback);
            }

            function lexec (id,lmethod,data) {
            	if (data) {
            		data.id=id;
            		data.lmethod=lmethod;
            		alert(data.pwd);
            		ajax_call('execute', data, alertreload_callback);
            	} else {
            		var dt={
            				id: id,
            				lmethod: lmethod,
            		};
            		ajax_call('execute', dt, alertreload_callback);
            	}	
            }
