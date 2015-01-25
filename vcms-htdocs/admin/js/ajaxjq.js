
function deleteobject (parseid,id,parseprm,deleteid) {
                var dt={
                    parseid: parseid,
                    id: id,
                    parseprm: parseprm,                 
                    deleteid: deleteid  
                };
                ajax_call_jq('deleteobject', dt, defcallbackjq);
}    

function deletealllow (id) {
    var dt={
        id: id
    };
    ajax_call_jq('deletealllow', dt, defcallbackjq);
}    


function resort (id) {
    var dt={
        id: id
    };
    ajax_call_jq('resort', dt, defcallbackjq);
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
                ajax_call_jq('addobject', dt, defcallbackjq);
}
            
 function exec (id,method) {
                var dt={
                    id: id,
                    method: method
                };
                ajax_call_jq('execute', dt, defcallbackjq);
 }

 function lexec (id,lmethod,data) {
            	if (data) {
            		data.id=id;
            		data.lmethod=lmethod;
            		ajax_call_jq('execute', data, defcallbackjq);
            	} else {
            		var dt={
            				id: id,
            				lmethod: lmethod
            		};
            		ajax_call_jq('execute', dt, defcallbackjq);
            	}	
 }

 
 function setvalue (id,prm,value) {
     var dt={
         id: id,
         prm: prm,
         value: value
     };
     ajax_call_jq('setvalue', dt, defcallbackjq);
}
