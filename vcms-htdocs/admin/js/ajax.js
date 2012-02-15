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

function deletealllow (id) {
    var dt={
        id: id
    };
    ajax_call('deletealllow', dt, alertreload_callback);
}    


function resort (id) {
    var dt={
        id: id
    };
    ajax_call('resort', dt, alertreload_callback);
}    


function addobject (up,link,linkval,name,upobj,method) {
                var dt={
                    up: up,
                    link: link,
                    name: name,
                    linkval: linkval,
                    upobj: upobj,
                    method:method
                };
                ajax_call('addobject', dt, alertreload_callback);
}
            
 function exec (id,method) {
                var dt={
                    id: id,
                    method: method
                };
                ajax_call('execute', dt, alertreload_callback);
 }

 function lexec (id,lmethod,data) {
            	if (data) {
            		data.id=id;
            		data.lmethod=lmethod;
            		ajax_call('execute', data, alertreload_callback);
            	} else {
            		var dt={
            				id: id,
            				lmethod: lmethod
            		};
            		ajax_call('execute', dt, alertreload_callback);
            	}	
 }

 
 function setvalue (id,prm,value) {
     var dt={
         id: id,
         prm: prm,
         value: value
     };
     ajax_call('setvalue', dt, alertreload_callback);
}
