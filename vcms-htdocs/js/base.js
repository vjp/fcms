function reloadPage (){
	window.location.href=window.location.href.sub(/\#$/,'');
}


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


function execute(func,data,callback,url) {
	new Ajax.Request(url || ajax_url || '/cgi-bin/ajax-json.pl', {
		method:'post',	
		parameters: {func: func, data: Object.toJSON(data)},
		onSuccess: function(transport) {
			var json = transport.responseText.evalJSON();
			callback(json)
		}
	});
}

function defcallback(json){
    if (json.status) {
        alert(json.message || lbSuccess); 
        reloadPage();
    } else {
        alert(json.message);
    }    
}   

function lexecute(func,objid,data,callback,url) {
	new Ajax.Request(url || ajax_url || '/cgi-bin/ajax-json.pl', {
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


var auth_success_func;
function auth_callback (json) {
      if (json.status) {
           var jar = new CookieJar({
              path: '/'
           });
           jar.put('auth',json);
           if (auth_success_func) auth_success_func();
      } else {
          alert(lbError+': '+json.message);
      }   
}

function auth(login,password,success_func) {
        var dt={
            login      : login,
            password   : password  
        };
        auth_success_func=success_func;
        execute('AUTH',dt,auth_callback);
}

function logout_callback (json) {
    if (json.status) {
         var jar = new CookieJar({
            path: '/'
         });
         jar.put('auth',json);
         location.href='/';
    } else {
        alert(lbError+': '+json.message);
    }   
}


function logout () {
		var dt={};
        execute('LOGOUT',dt,logout_callback);
}	

function setVCallback (json) {
	if (json.status) {
		alert(lbSuccess);
    } else {
        alert(lbError+': '+json.message);
    }   
}


function setMVCallback (json) {
	var url=document.location.href;
	if (json.status) {
		alert(json.message || lbSuccess);
        if (json.back) {
	           location.href=json.back;
        } else {
        	   reloadPage();
	    }    
    } else {
        alert(lbError+': '+json.message);
    }   
}




function set (objid,prm,fcallback) {
	var inputid='_o'+objid+'_p'+prm;
	var dt={
            prm     : prm,
            value   : $(inputid).value
    };
	lexecute('BASESAVEMETHOD',objid,dt,fcallback || setVCallback);

}

function multiset (frm,fcallback,back,method) {
	var dt=$(frm).up('form').serialize(true);
	dt.back=back;
	execute(method || 'BASELPARSER',dt,fcallback || setMVCallback);
}

function multisetsingleobj (frm,id,fcallback,back,method) {
	var dt=$(frm).up('form').serialize(true);
	dt.back=back;
	lexecute(method || 'BASELPARSER',id,dt,fcallback || setMVCallback);
}


function prepareMouseOverImage(image, originalURL)
{
	image.mouseOverImage=originalURL;
	image.onload=function(){return true;};
	try {
		image.normalImage=grayscale(image, false);
		image.onmouseover=function()
		{
			this.src=this.mouseOverImage;
		}
		image.onmouseout=function()
		{
			this.src=this.normalImage;
		}
		image.src=image.normalImage;
	}
	catch(e) { }
}
 
 
function grayscale(image, bPlaceImage)
{
  var myCanvas=document.createElement("canvas");
  var myCanvasContext=myCanvas.getContext("2d");
 
  var imgWidth=image.width;
  var imgHeight=image.height;
  // You'll get some string error if you fail to specify the dimensions
  myCanvas.width= imgWidth;
  myCanvas.height=imgHeight;
//  alert(imgWidth);
  myCanvasContext.drawImage(image,0,0);
 
  // The getImageData() function cannot be called if the image is not from the same domain.
  // You'll get security error
  var imageData=myCanvasContext.getImageData(0,0, imgWidth, imgHeight);
  for (i=0; i<imageData.height; i++)
  {
    for (j=0; j<imageData.width; j++)
    {
	  var index=(i*4)*imageData.width+(j*4);
	  var red=imageData.data[index];
	  var green=imageData.data[index+1];
	  var blue=imageData.data[index+2];
	  var alpha=imageData.data[index+3];
	  var average=(red+green+blue)/3;
   	  imageData.data[index]=average;
   	  imageData.data[index+1]=average;
   	  imageData.data[index+2]=average;
   	  imageData.data[index+3]=alpha;
	}
  }
  myCanvasContext.putImageData(imageData,0,0,0,0, imageData.width, imageData.height);
 // myCanvasContext.drawIMage(imageData,0,0);//,0,0, imageData.width, imageData.height);
 
  if (bPlaceImage)
  {
	  var myDiv=document.createElement("div");
	  myDiv.appendChild(myCanvas);
	  image.parentNode.appendChild(myCanvas);//, image);
  }
  return myCanvas.toDataURL();
}