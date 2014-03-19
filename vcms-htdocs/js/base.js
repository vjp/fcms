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
})();


function getElementsByTagAndClass (tagName,className) {
	 var elms = new Array ();
	 var allTags = document.getElementsByTagName(tagName);
	 for (var i=0; tag = allTags[i]; i++){
		 if (hasClass(tag,className)) elms.push(tag);
	 }	 
	 return elms;
}


function execute(func,data,callback,url) {
	var def_url=(typeof(ajax_url) != "undefined")?ajax_url:'/cgi-bin/ajax-json.pl';
	new Ajax.Request(url || def_url, {
		method:'post',	
		parameters: {func: func, data: Object.toJSON(data)},
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

function defcallback(json){
    if (json.status) {
        alert(json.message || lbSuccess);
        if (json.redir) {
        	location.href=json.redir;
        } else {
        	reloadPage();
        }	
    } else {
        alert(json.message);
    }    
}   

function lexecute(func,objid,data,callback,url) {
	var def_url=(typeof(ajax_url) != "undefined")?ajax_url:'/cgi-bin/ajax-json.pl';
	new Ajax.Request(url || def_url, {
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
		if (json.reload) reloadPage();
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




function set (objid,prm,fcallback,reload) {
	var oinputid='_o'+objid+'_p'+prm;
	var pinputid='_p'+prm;
	var val;
	if ($(oinputid)) val=$(oinputid).value;
	else if ($(pinputid)) val=$(pinputid).value;
	var dt={
            prm     : prm,
            value   : val,
            reload  : reload
    };
	lexecute('BASESAVEMETHOD',objid,dt,fcallback || setVCallback);

}

function multiset (frm,fcallback,back,method,sortid) {
	var dt=$(frm).up('form').serialize(true);
	if (sortid) {
		dt.sortstr=Sortable.serialize(sortid);
	} else if ($('sortableList')) {
		dt.sortstr=Sortable.serialize('sortableList');
	}
	dt.back=back;
	execute(method || 'BASELPARSER',dt,fcallback || setMVCallback);
}

function multisetsingleobj (frm,id,fcallback,back,method) {
	var nnattr=$(frm).up('form').select('input[notnull="1"]','select[notnull="1"]');
	console.log('func multisetsingleobj: id='+id+' method='+method);
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
	}
	
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



// (c) http://www.chrisnetonline.com/lab/scrollabletable/
function render_scrollable_table(id, scroll_height) {
    var container  = $(id);
    var tbl_orig   = container.select('table').first();
    tbl_orig.setStyle({'width':(tbl_orig.getWidth())-18 +'px'});
    var tbl_header = tbl_orig.select('thead').first();
    var tbl_body   = tbl_orig.select('tbody').first();
    if (typeof tbl_header != 'undefined' && typeof tbl_body != 'undefined') {
    
        // Remove the tbody style so we can get the height of the actual rows.
        tbl_body.setStyle({'height': null});
        var actual_height = tbl_body.getHeight();

        // Get the width of the table.
        var total_width = tbl_orig.getWidth();

        // Set the width of the container div.
       
        container.setStyle({'width': total_width + 'px'});

        // Don't add the fixed height and scroll box if there isn't enough content to scroll.
        if (actual_height > scroll_height) {
            var col_widths = new Array();

            // Add fixed widths to the table header columns.
            tbl_header.select('td','th').each(function(item, index) {
                col_widths[index] = item.getWidth();
                item.writeAttribute({'width': col_widths[index]});
            });
            
  
            // Add fixed widths to the table body columns.
            tbl_body.select('tr').each(function(item, index) {
                if (item.select('td').length==col_widths.length) {
                   item.select('td').each(function(item, index) {
                      item.writeAttribute({'width': col_widths[index]});
                   });
                }
            });


            // Remove header and body from the original table.
            var tmp_header = tbl_header.remove();
            var tmp_body   = tbl_body.remove();

            // Update the width of the container div.
            container.setStyle({'width': (total_width + 18) + 'px'});

            // Create table to hold the scrollable body.
            var tmp_tbl_body = $(tbl_orig.cloneNode(true));
            tmp_tbl_body.insert(tmp_body);
            tmp_tbl_body.setStyle({'height': scroll_height + 'px'});

            // Add fixed header back into the DOM.
            var tmp_tbl_header = $(tbl_orig.cloneNode(true));
            tmp_tbl_header.insert(tmp_header);
            container.insert(tmp_tbl_header);

            // Add scrollable body into the DOM.
            var scroll_box = new Element('div', {'style': 'height: ' + scroll_height + 'px; overflow: auto;'});
            scroll_box.insert(tmp_tbl_body);
            container.insert(scroll_box);

            // Remove original table.
            tbl_orig.remove();
        }
    }
}


function blink (id) {
    var i = document.getElementById(id);
    if(i.style.visibility=='hidden') {
        i.style.visibility='visible';
    } else {
        i.style.visibility='hidden';
    }
    setTimeout("blink('"+id+"')",1000);
}


function openPopup(url,wndprops) {
	var wndobj={};
	if (wndprops) wndobj=wndprops;
	wndobj.isUrl=true;
	wndobj.id='ppWindow';
    var ppIt = new PopIt(url,wndobj);
}

function closePopup () {
    popIts.activePopIts['ppWindow'].close();
}

function jsErrHandler(message, url, line)
{
    if (navigator.userAgent.search('Firefox') != -1 && message === 'Error loading script') {
        return true;
    }
    if (typeof(errorCnt) != "undefined") {
    	errorCnt++;
    	if (errorCnt>1) return true;
    }
    new Ajax.Request('/cgi-bin/ajax-json.pl', {
            method:'post',  
            parameters: {func: 'JSERROR', data: Object.toJSON({message:message,url:url,line:line,ua:navigator.userAgent})}
    });
    return true;
}


function successSet () {
    alert(lbSelSuccess);
    parent.closePopup();
    parent.reloadPage();
}

function setSel(frm,id) {
    var dt=$(frm).up('form').serialize(true);
    lexecute('BASELPARSER',id,dt,successSet);
}
