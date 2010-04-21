function setCookie (name, value, expires, path, domain, secure) {
      document.cookie = name + "=" + escape(value) +
        "; expires=+1d" +
        "; path=/" +
        ((domain) ? "; domain=" + domain : "") +
        ((secure) ? "; secure" : "");

}


function getCookie( name ) {
    var start = document.cookie.indexOf( name + "=" );
    var len = start + name.length + 1;
    if ( ( !start ) && ( name != document.cookie.substring( 0, name.length ) ) ) {
        return null;
    }
    if ( start == -1 ) return null;
    var end = document.cookie.indexOf( ';', len );
    if ( end == -1 ) end = document.cookie.length;
    return unescape( document.cookie.substring( len, end ) );
}


function openWindow(url,w,h,sbars,resize) {
	window.open(url,"","toolbar=no, location=no, directories=no, status=no, menubar=no, scrollbars="+sbars+", resizable="+resize+", width=350, height=250");
}


var hasClass = (function (){
	var reCache = {}
	return function (element, className){
		return (reCache[className] ? reCache[className] : (reCache[className] = new RegExp("(?:\\s|^)" + className + "(?:\\s|$)"))).test(element.className)
	}
})()


function getElementsByTagAndClass (tagName,className) {
	 var elms = new Array ();
	 var allTags = document.getElementsByTagName(tagName);
	 for (var i=0; tag = allTags[i]; i++){
		 if (hasClass(tag,className)) elms.push(tag);
	 }	 
	 return elms;
}


function execute(func,data,callback) {
	new Ajax.Request('/cgi-bin/ajax-json.pl', {
		method:'post',	
		parameters: {func: func, data: Object.toJSON(data)},
		onSuccess: function(transport) {
			var json = transport.responseText.evalJSON();
			callback(json)
		}
	});
}



function ajax_call(func,data,callback) {
		new Ajax.Request('ajax-json.pl', {
			method:'post',	
			parameters: {func: func, data: Object.toJSON(data)},
			onSuccess: function(transport) {
				var json = transport.responseText.evalJSON();
				callback(json)
			}
		});
}


function validEmail (email) {
	var emailRegEx = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
	return email.match(emailRegEx);

}


var auth_callback_func;
function auth_callback (json) {
      if (json.status) {
           var jar = new CookieJar({
              path: '/',
           })
           jar.put('auth',json);
           if (auth_callback_func) auth_callback_func();
      } else {
          alert(lbError+': '+json.message);
      }   
}

function auth(login,password,callback_func) {
        var dt={
            login      : login,
            password   : password,  
        };
        auth_callback_func=callback_func;
        execute('AUTH',dt,auth_callback);
}


