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

            function lexec (id,lmethod) {
                var dt={
                    id: id,
                    lmethod: lmethod,
                };
                ajax_call('execute', dt, alertreload_callback);
            }
